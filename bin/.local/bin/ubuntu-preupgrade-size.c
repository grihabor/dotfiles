#!/usr/bin/env -S c-script
//cc: -O2 -Wall -Wextra
/*
 * ubuntu-preupgrade-size — fast backup-size estimator.
 *
 * This is a drop-in replacement for the slow Bash "measuring" phase of
 * ubuntu-preupgrade-backup.sh (the size_of / du_bytes / show_breakdown
 * logic). The Bash version re-read the whole NUL-separated plan file for
 * every queried path and shelled out to `du` once per matched entry, which
 * was quadratic and spawned thousands of processes on large home trees.
 *
 * Instead we read the plan once, compute the apparent size of every plan
 * entry in a single filesystem walk, and answer every size query from a
 * sorted index with prefix sums. The sizing rules are identical to the old
 * size_of(): the plan is the single source of truth, so the estimate matches
 * exactly what the final rsync copies.
 *
 * For a queried path P, size_of(P) is:
 *   * if any plan entry is P or lives under P/  -> sum of those entries'
 *     apparent sizes (P was split; only its wanted content counts), else
 *   * if P lives inside a wholesale (clean) plan entry -> apparent size of P
 *     itself (its whole subtree is backed up), else
 *   * 0 (P is excluded and contributes nothing).
 *
 * The program walks the requested top-level ROOT directories, printing a
 * "<bytes>\t<path>" line for each, and recursing into the immediate
 * subdirectories of any entry at least --breakdown-threshold bytes, listing
 * those at least --display-threshold bytes (same rule as the old Bash
 * breakdown). Progress is logged to stderr so it never mixes into the output.
 * A final "<total>\tTOTAL" line carries the summed top-level size.
 *
 * Usage:
 *   ubuntu-preupgrade-size --plan FILE \
 *       [--breakdown-threshold BYTES] [--display-threshold BYTES] -- ROOT...
 */

#define _GNU_SOURCE
#include <dirent.h>
#include <errno.h>
#include <stdarg.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <time.h>
#include <unistd.h>

/* ---- the plan (sorted array of absolute paths) --------------------------- */

static char *g_buf;         /* whole plan file, NUL-separated entries         */
static char **g_plan;       /* pointers into g_buf, sorted lexicographically  */
static size_t g_nplan;
static long long *g_cum;    /* cum[i] = sum of apparent sizes of plan[0..i-1] */

/* ---- logging (mirrors ubuntu-preupgrade-plan) ---------------------------- */

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

static void *xmalloc(size_t n)
{
    void *p = malloc(n);
    if (!p) {
        perror("malloc");
        exit(1);
    }
    return p;
}

/* ---- path helpers (mirrors ubuntu-preupgrade-plan) ----------------------- */

static char *path_join(const char *dir, const char *name)
{
    size_t dl = strlen(dir);
    size_t nl = strlen(name);
    int slash = (dl > 0 && dir[dl - 1] == '/') ? 0 : 1;
    char *p = xmalloc(dl + slash + nl + 1);
    memcpy(p, dir, dl);
    if (slash)
        p[dl] = '/';
    memcpy(p + dl + slash, name, nl + 1);
    return p;
}

/* ---- apparent size (like `du -x --apparent-size`) ------------------------ */
/*
 * Sum of st_size over `path` and its whole subtree, staying on the same
 * filesystem as `path` and never following symlinked directories. Files and
 * symlinks contribute their own st_size; directory inodes contribute nothing,
 * matching `du --apparent-size` (the Bash version this replaces used
 * `du -s -x --apparent-size --block-size=1`) so the estimate lines up exactly.
 */
static long long apparent_size_dev(const char *path, dev_t dev)
{
    struct stat st;
    if (lstat(path, &st) != 0)
        return 0;

    if (!S_ISDIR(st.st_mode) || S_ISLNK(st.st_mode) || st.st_dev != dev)
        return st.st_size;

    long long total = 0; /* directory inode size is not counted by du */

    DIR *d = opendir(path);
    if (!d)
        return total;

    struct dirent *de;
    while ((de = readdir(d))) {
        if (strcmp(de->d_name, ".") == 0 || strcmp(de->d_name, "..") == 0)
            continue;
        char *child = path_join(path, de->d_name);
        total += apparent_size_dev(child, dev);
        free(child);
    }
    closedir(d);
    return total;
}

static long long apparent_size(const char *path)
{
    struct stat st;
    if (lstat(path, &st) != 0)
        return 0;
    return apparent_size_dev(path, st.st_dev);
}

/* ---- sorted-plan queries ------------------------------------------------- */

static int cmp_str(const void *a, const void *b)
{
    return strcmp(*(const char *const *)a, *(const char *const *)b);
}

/* First index i with g_plan[i] >= key (lower_bound). */
static size_t lower_bound(const char *key)
{
    size_t lo = 0, hi = g_nplan;
    while (lo < hi) {
        size_t mid = lo + (hi - lo) / 2;
        if (strcmp(g_plan[mid], key) < 0)
            lo = mid + 1;
        else
            hi = mid;
    }
    return lo;
}

/*
 * size_of() — identical semantics to the Bash original, see the file header.
 * Uses the sorted plan plus prefix sums so each query is O(log n).
 */
static long long size_of(const char *path)
{
    size_t plen = strlen(path);

    /* "path/" prefix and its exclusive upper bound ("path" + 0x30, since the
     * trailing '/' (0x2f) is the smallest byte that can follow the name). */
    char *prefix = xmalloc(plen + 2);
    memcpy(prefix, path, plen);
    prefix[plen] = '/';
    prefix[plen + 1] = '\0';

    char *pend = xmalloc(plen + 2);
    memcpy(pend, path, plen);
    pend[plen] = '/' + 1;
    pend[plen + 1] = '\0';

    size_t a = lower_bound(prefix); /* first entry under path/ */
    size_t b = lower_bound(pend);   /* first entry past path/  */
    long long under = g_cum[b] - g_cum[a];

    /* Is `path` itself a plan entry? */
    size_t lo = lower_bound(path);
    int exact = (lo < g_nplan && strcmp(g_plan[lo], path) == 0);
    long long exact_size = exact ? (g_cum[lo + 1] - g_cum[lo]) : 0;

    long long result;
    if (b > a || exact) {
        /* Path was split: only its wanted (planned) content counts. */
        result = under + exact_size;
    } else if (lo > 0) {
        /* No plan entry at/under path. If the nearest preceding entry is an
         * ancestor, path sits inside a wholesale clean dir and is fully
         * backed up, so measure it directly. */
        const char *pred = g_plan[lo - 1];
        size_t prl = strlen(pred);
        if (plen > prl && strncmp(path, pred, prl) == 0 && path[prl] == '/')
            result = apparent_size(path);
        else
            result = 0;
    } else {
        result = 0;
    }

    free(prefix);
    free(pend);
    return result;
}

/* ---- breakdown output ---------------------------------------------------- */

static long long g_breakdown_threshold = -1; /* disabled by default */
static long long g_display_threshold;

static void show_breakdown(const char *parent, dev_t dev);

static void print_entry(const char *path, long long size, dev_t dev)
{
    printf("%lld\t%s\n", size, path);
    if (g_breakdown_threshold >= 0 && size >= g_breakdown_threshold)
        show_breakdown(path, dev);
}

/* Immediate subdirectories of `parent` (same filesystem, no symlinks) whose
 * plan-derived size is at least --display-threshold, in readdir order. */
static void show_breakdown(const char *parent, dev_t dev)
{
    DIR *d = opendir(parent);
    if (!d)
        return;

    struct dirent *de;
    while ((de = readdir(d))) {
        if (strcmp(de->d_name, ".") == 0 || strcmp(de->d_name, "..") == 0)
            continue;
        char *child = path_join(parent, de->d_name);

        struct stat st;
        if (lstat(child, &st) == 0 && S_ISDIR(st.st_mode) &&
            !S_ISLNK(st.st_mode) && st.st_dev == dev) {
            long long size = size_of(child);
            if (size >= g_display_threshold)
                print_entry(child, size, dev);
        }
        free(child);
    }
    closedir(d);
}

/* ---- plan loading -------------------------------------------------------- */

static void load_plan(const char *file)
{
    FILE *f = fopen(file, "rb");
    if (!f) {
        fprintf(stderr, "ERROR: cannot open plan file %s: %s\n", file,
                strerror(errno));
        exit(1);
    }

    size_t cap = 1 << 20, len = 0;
    g_buf = xmalloc(cap);
    size_t n;
    while ((n = fread(g_buf + len, 1, cap - len, f)) > 0) {
        len += n;
        if (len == cap) {
            cap *= 2;
            g_buf = realloc(g_buf, cap);
            if (!g_buf) {
                perror("realloc");
                exit(1);
            }
        }
    }
    fclose(f);

    /* Split on NUL into the plan array. */
    size_t pcap = 1024;
    g_plan = xmalloc(pcap * sizeof(*g_plan));
    size_t start = 0;
    for (size_t i = 0; i < len; i++) {
        if (g_buf[i] != '\0')
            continue;
        if (i > start) { /* skip empty entries */
            if (g_nplan == pcap) {
                pcap *= 2;
                g_plan = realloc(g_plan, pcap * sizeof(*g_plan));
                if (!g_plan) {
                    perror("realloc");
                    exit(1);
                }
            }
            g_plan[g_nplan++] = g_buf + start;
        }
        start = i + 1;
    }

    qsort(g_plan, g_nplan, sizeof(*g_plan), cmp_str);

    /* Apparent size of every plan entry, in one walk, plus prefix sums. */
    vlog("Measuring %zu planned path(s)...", g_nplan);
    g_cum = xmalloc((g_nplan + 1) * sizeof(*g_cum));
    g_cum[0] = 0;
    for (size_t i = 0; i < g_nplan; i++)
        g_cum[i + 1] = g_cum[i] + apparent_size(g_plan[i]);
    vlog("Measured planned paths (%lld bytes total).", g_cum[g_nplan]);
}

/* ---- main ---------------------------------------------------------------- */

int main(int argc, char **argv)
{
    const char *plan_file = NULL;
    char **roots = NULL;
    size_t nroots = 0, rcap = 0;

    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "--plan") == 0 && i + 1 < argc) {
            plan_file = argv[++i];
        } else if (strcmp(argv[i], "--breakdown-threshold") == 0 &&
                   i + 1 < argc) {
            g_breakdown_threshold = atoll(argv[++i]);
        } else if (strcmp(argv[i], "--display-threshold") == 0 &&
                   i + 1 < argc) {
            g_display_threshold = atoll(argv[++i]);
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

    if (!plan_file || nroots == 0) {
        fprintf(stderr,
                "Usage: %s --plan FILE [--breakdown-threshold BYTES] "
                "[--display-threshold BYTES] -- ROOT...\n",
                argv[0]);
        return 2;
    }

    load_plan(plan_file);

    long long total = 0;
    for (size_t i = 0; i < nroots; i++) {
        struct stat st;
        if (lstat(roots[i], &st) != 0 || !S_ISDIR(st.st_mode))
            continue;
        vlog("  measuring %s", roots[i]);
        long long size = size_of(roots[i]);
        print_entry(roots[i], size, st.st_dev);
        total += size;
    }

    /* Final line carries the summed top-level size for the caller. */
    printf("%lld\tTOTAL\n", total);
    fflush(stdout);
    vlog("Size estimation complete.");
    return 0;
}
