#!/usr/bin/env -S c-script
//cc: -O2 -Wall -Wextra
/*
 * ubuntu-preupgrade-plan — fast backup-plan generator.
 *
 * This is a drop-in replacement for the slow Bash "planning" phase of
 * ubuntu-preupgrade-backup.sh (the detect_exclusions + build_plan logic).
 * It walks the requested root directories once, decides what to exclude,
 * and prints a NUL-separated backup plan on stdout. Progress is logged to
 * stderr so it never mixes into the plan.
 *
 * Each plan entry is either:
 *   * a directory whose whole subtree is wanted (copied recursively), or
 *   * an individual file/symlink living in a directory we had to split
 *     because it also contains excluded content.
 * A directory is split (its children listed individually) only when it
 * actually contains something excluded; otherwise it is listed wholesale.
 *
 * Exclusions:
 *   * --exclude NAME        a directory whose basename equals NAME
 *   * --marker FILE:DIR     when a directory contains a file named FILE,
 *                           its sibling subdirectory named DIR is excluded
 *                           (e.g. Cargo.toml:target, pants.toml:dist)
 *
 * Traversal stays on a single filesystem per root (like find -xdev /
 * fd --one-file-system) and never follows symlinked directories.
 *
 * Usage:
 *   ubuntu-preupgrade-plan [--exclude NAME]... [--marker FILE:DIR]... ROOT...
 */

#define _GNU_SOURCE
#include <dirent.h>
#include <errno.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <time.h>
#include <unistd.h>

/* ---- configuration parsed from argv -------------------------------------- */

static char **g_excludes;   /* directory basenames to exclude            */
static size_t g_nexcludes;

static char **g_marker_file; /* marker file names (e.g. Cargo.toml)      */
static char **g_marker_dir;  /* sibling dir to exclude (e.g. target)     */
static size_t g_nmarkers;

/* ---- tiny string hash set (open addressing) ------------------------------ */

typedef struct {
    char **slots;
    size_t cap;   /* power of two */
    size_t len;
} strset;

static unsigned long str_hash(const char *s)
{
    unsigned long h = 1469598103934665603UL; /* FNV-1a */
    for (; *s; s++) {
        h ^= (unsigned char)*s;
        h *= 1099511628211UL;
    }
    return h;
}

static void set_init(strset *s)
{
    s->cap = 1024;
    s->len = 0;
    s->slots = calloc(s->cap, sizeof(*s->slots));
    if (!s->slots) {
        perror("calloc");
        exit(1);
    }
}

static void set_put_raw(strset *s, char *key)
{
    size_t mask = s->cap - 1;
    size_t i = str_hash(key) & mask;
    while (s->slots[i]) {
        if (strcmp(s->slots[i], key) == 0)
            return; /* already present */
        i = (i + 1) & mask;
    }
    s->slots[i] = key;
    s->len++;
}

static void set_grow(strset *s)
{
    size_t oldcap = s->cap;
    char **old = s->slots;
    s->cap *= 2;
    s->len = 0;
    s->slots = calloc(s->cap, sizeof(*s->slots));
    if (!s->slots) {
        perror("calloc");
        exit(1);
    }
    for (size_t i = 0; i < oldcap; i++)
        if (old[i])
            set_put_raw(s, old[i]);
    free(old);
}

/* Inserts a copy of key. */
static void set_add(strset *s, const char *key)
{
    if ((s->len + 1) * 10 >= s->cap * 7) /* keep load factor < 0.7 */
        set_grow(s);
    char *copy = strdup(key);
    if (!copy) {
        perror("strdup");
        exit(1);
    }
    set_put_raw(s, copy);
}

static int set_has(const strset *s, const char *key)
{
    size_t mask = s->cap - 1;
    size_t i = str_hash(key) & mask;
    while (s->slots[i]) {
        if (strcmp(s->slots[i], key) == 0)
            return 1;
        i = (i + 1) & mask;
    }
    return 0;
}

static strset g_excluded; /* absolute paths excluded outright            */
static strset g_dirty;    /* dirs with an exclusion somewhere below them  */

/* ---- logging ------------------------------------------------------------- */

static void vlog(const char *fmt, ...)
{
    char ts[16];
    time_t t = time(NULL);
    struct tm tm;
    localtime_r(&t, &tm);
    strftime(ts, sizeof ts, "%H:%M:%S", &tm);
    fprintf(stderr, "[%s] ", ts);

    va_list ap;
    va_start(ap, fmt);
    vfprintf(stderr, fmt, ap);
    va_end(ap);
    fputc('\n', stderr);
}

/* ---- path helpers -------------------------------------------------------- */

/* Joins dir + "/" + name into a freshly malloc'd string. */
static char *path_join(const char *dir, const char *name)
{
    size_t dl = strlen(dir);
    size_t nl = strlen(name);
    int slash = (dl > 0 && dir[dl - 1] == '/') ? 0 : 1;
    char *p = malloc(dl + slash + nl + 1);
    if (!p) {
        perror("malloc");
        exit(1);
    }
    memcpy(p, dir, dl);
    if (slash)
        p[dl] = '/';
    memcpy(p + dl + slash, name, nl + 1);
    return p;
}

static int name_excluded(const char *name)
{
    for (size_t i = 0; i < g_nexcludes; i++)
        if (strcmp(name, g_excludes[i]) == 0)
            return 1;
    return 0;
}

/* ---- phase 1: discover exclusions and dirty directories ------------------ */
/*
 * Returns 1 if the subtree rooted at `dir` contains any excluded path, so the
 * caller can mark its own ancestors dirty. `dir` is assumed to be a real
 * directory on device `dev`. Records excluded paths in g_excluded and dirty
 * directories in g_dirty.
 */
static int scan(const char *dir, dev_t dev)
{
    DIR *d = opendir(dir);
    if (!d)
        return 0;

    /* First pass over entries: note which marker files are present so we can
     * apply the marker->sibling exclusion rule for this directory. */
    struct dirent *de;
    int *marker_present = calloc(g_nmarkers ? g_nmarkers : 1, sizeof(int));
    if (!marker_present) {
        perror("calloc");
        exit(1);
    }

    /* We need two logical passes but readdir is single-pass; collect names. */
    char **names = NULL;
    size_t nnames = 0, cap = 0;
    while ((de = readdir(d))) {
        if (strcmp(de->d_name, ".") == 0 || strcmp(de->d_name, "..") == 0)
            continue;
        if (nnames == cap) {
            cap = cap ? cap * 2 : 64;
            names = realloc(names, cap * sizeof(*names));
            if (!names) {
                perror("realloc");
                exit(1);
            }
        }
        names[nnames] = strdup(de->d_name);
        if (!names[nnames]) {
            perror("strdup");
            exit(1);
        }
        for (size_t m = 0; m < g_nmarkers; m++)
            if (strcmp(de->d_name, g_marker_file[m]) == 0)
                marker_present[m] = 1;
        nnames++;
    }
    closedir(d);

    int dirty = 0;

    for (size_t i = 0; i < nnames; i++) {
        const char *name = names[i];
        char *child = path_join(dir, name);

        struct stat st;
        if (lstat(child, &st) != 0) {
            free(child);
            continue;
        }

        int is_dir = S_ISDIR(st.st_mode);
        int is_link = S_ISLNK(st.st_mode);

        /* Decide whether this child is excluded. */
        int excluded = 0;
        if (is_dir && name_excluded(name)) {
            excluded = 1;
        } else if (is_dir) {
            for (size_t m = 0; m < g_nmarkers; m++) {
                if (marker_present[m] &&
                    strcmp(name, g_marker_dir[m]) == 0) {
                    excluded = 1;
                    break;
                }
            }
        }

        if (excluded) {
            set_add(&g_excluded, child);
            dirty = 1;
        } else if (is_dir && !is_link && st.st_dev == dev) {
            if (scan(child, dev))
                dirty = 1;
        }
        free(child);
    }

    for (size_t i = 0; i < nnames; i++)
        free(names[i]);
    free(names);
    free(marker_present);

    if (dirty)
        set_add(&g_dirty, dir);
    return dirty;
}

/* ---- phase 2: emit the plan --------------------------------------------- */

static void emit(const char *path)
{
    fputs(path, stdout);
    fputc('\0', stdout);
}

/* Emits the wanted content of a split directory (see header comment). */
static void plan_dir(const char *dir, dev_t dev)
{
    DIR *d = opendir(dir);
    if (!d)
        return;

    struct dirent *de;
    while ((de = readdir(d))) {
        if (strcmp(de->d_name, ".") == 0 || strcmp(de->d_name, "..") == 0)
            continue;
        char *child = path_join(dir, de->d_name);

        if (set_has(&g_excluded, child)) {
            free(child);
            continue;
        }

        struct stat st;
        if (lstat(child, &st) != 0) {
            free(child);
            continue;
        }

        if (S_ISDIR(st.st_mode) && !S_ISLNK(st.st_mode) &&
            st.st_dev == dev) {
            if (set_has(&g_dirty, child))
                plan_dir(child, dev); /* split: contains exclusions */
            else
                emit(child);          /* wholesale: clean subtree */
        } else {
            emit(child);              /* file or symlink */
        }
        free(child);
    }
    closedir(d);
}

/* ---- argument parsing ---------------------------------------------------- */

static void add_exclude(const char *name)
{
    g_excludes = realloc(g_excludes, (g_nexcludes + 1) * sizeof(*g_excludes));
    if (!g_excludes) {
        perror("realloc");
        exit(1);
    }
    g_excludes[g_nexcludes++] = strdup(name);
}

static void add_marker(const char *spec)
{
    const char *colon = strchr(spec, ':');
    if (!colon || colon == spec || colon[1] == '\0') {
        fprintf(stderr, "ERROR: --marker expects FILE:DIR, got '%s'\n", spec);
        exit(2);
    }
    size_t flen = (size_t)(colon - spec);
    char *file = malloc(flen + 1);
    char *d = strdup(colon + 1);
    if (!file || !d) {
        perror("malloc");
        exit(1);
    }
    memcpy(file, spec, flen);
    file[flen] = '\0';

    g_marker_file = realloc(g_marker_file,
                            (g_nmarkers + 1) * sizeof(*g_marker_file));
    g_marker_dir = realloc(g_marker_dir,
                           (g_nmarkers + 1) * sizeof(*g_marker_dir));
    if (!g_marker_file || !g_marker_dir) {
        perror("realloc");
        exit(1);
    }
    g_marker_file[g_nmarkers] = file;
    g_marker_dir[g_nmarkers] = d;
    g_nmarkers++;
}

int main(int argc, char **argv)
{
    char **roots = NULL;
    size_t nroots = 0, rcap = 0;

    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "--exclude") == 0 && i + 1 < argc) {
            add_exclude(argv[++i]);
        } else if (strcmp(argv[i], "--marker") == 0 && i + 1 < argc) {
            add_marker(argv[++i]);
        } else if (strcmp(argv[i], "--") == 0) {
            for (int j = i + 1; j < argc; j++) {
                if (nroots == rcap) {
                    rcap = rcap ? rcap * 2 : 16;
                    roots = realloc(roots, rcap * sizeof(*roots));
                }
                roots[nroots++] = argv[j];
            }
            break;
        } else if (argv[i][0] == '-' && argv[i][1] != '\0') {
            fprintf(stderr, "ERROR: unknown option: %s\n", argv[i]);
            return 2;
        } else {
            if (nroots == rcap) {
                rcap = rcap ? rcap * 2 : 16;
                roots = realloc(roots, rcap * sizeof(*roots));
            }
            roots[nroots++] = argv[i];
        }
    }

    if (nroots == 0) {
        fprintf(stderr,
                "Usage: %s [--exclude NAME]... [--marker FILE:DIR]... ROOT...\n",
                argv[0]);
        return 2;
    }

    set_init(&g_excluded);
    set_init(&g_dirty);

    /* Phase 1: one walk to discover exclusions. */
    vlog("Scanning for excludable directories (caches, build dirs)...");
    for (size_t i = 0; i < nroots; i++) {
        struct stat st;
        if (lstat(roots[i], &st) != 0 || !S_ISDIR(st.st_mode))
            continue;
        scan(roots[i], st.st_dev);
    }
    vlog("Found %zu excluded path(s).", g_excluded.len);

    /* Phase 2: emit the plan. */
    vlog("Building backup plan...");
    for (size_t i = 0; i < nroots; i++) {
        struct stat st;
        if (lstat(roots[i], &st) != 0 || !S_ISDIR(st.st_mode))
            continue;
        vlog("  planning %s", roots[i]);
        /* A root is only emitted wholesale if its whole subtree is clean. */
        if (set_has(&g_dirty, roots[i]))
            plan_dir(roots[i], st.st_dev);
        else
            emit(roots[i]);
    }
    /* Flush the NUL-separated plan before the final log so stdout/stderr
     * appear in order, then emit a trailing newline to stderr so a terminal
     * prompt is not glued to the last (newline-less) plan entry. The plan on
     * stdout stays pure NUL-separated for rsync --from0. */
    fflush(stdout);
    vlog("Backup plan built.");
    fputc('\n', stderr);

    return 0;
}
