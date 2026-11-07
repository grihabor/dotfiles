#!/usr/bin/env bash
set -Eeuo pipefail

# Usage:
#   sudo ./ubuntu-preupgrade-backup.sh /media/username/BackupDrive
#   sudo ./ubuntu-preupgrade-backup.sh --only-estimate-size [/path]

usage() {
    echo "Usage: sudo $0 [--only-estimate-size] /path/to/external/drive"
    echo "       sudo $0 --only-estimate-size"
    exit 1
}

if [[ $EUID -ne 0 ]]; then
    echo "ERROR: Run with sudo."
    exit 1
fi

# Parse options; collect positional arguments separately.
ONLY_ESTIMATE=0
POSITIONAL=()
for arg in "$@"; do
    case "$arg" in
    --only-estimate-size) ONLY_ESTIMATE=1 ;;
    -h | --help) usage ;;
    -*)
        echo "ERROR: Unknown option: $arg"
        usage
        ;;
    *) POSITIONAL+=("$arg") ;;
    esac
done
set -- ${POSITIONAL[@]+"${POSITIONAL[@]}"}

# A destination is required for a real backup, but optional when only
# estimating size (in that case the available-space check is skipped).
if [[ $# -gt 1 ]]; then
    usage
fi
if [[ $ONLY_ESTIMATE -eq 0 && $# -ne 1 ]]; then
    usage
fi

DEST=""
if [[ $# -eq 1 ]]; then
    if [[ ! -d "$1" ]]; then
        usage
    fi

    DEST=$(realpath -e -- "$1")
    MOUNT=$(findmnt -n -o TARGET -T "$DEST")

    # Protect against accidentally backing up onto the system disk.
    if [[ "$MOUNT" == "/" ]]; then
        echo "ERROR: Destination is not on a separate mounted filesystem."
        exit 1
    fi

    case "$DEST/" in
    /home/*)
        echo "ERROR: Backup destination must not be inside /home."
        exit 1
        ;;
    esac
fi

command -v rsync >/dev/null || {
    echo "Install rsync first: sudo apt install rsync"
    exit 1
}

# Directories to back up
DIRECTORIES=(
    /etc
    /home
    /root
    /usr/local
    /boot
    /var/lib/dpkg
    /var/lib/apt
    /var/lib/snapd
    /var/lib/flatpak
    /var/lib/NetworkManager
    /var/lib/bluetooth
    /var/lib/AccountsService
    /var/lib/systemd
    /var/spool/cron
    /srv
    /var/www
    /var/backups
)

# Paths excluded everywhere: estimation, breakdown display, and backup.
# Patterns are matched against any directory level (e.g. per-user $HOME).
EXCLUDES=(
    '.cache'              # generic user cache, re-created on demand
    '.steam'             # Steam client files, re-downloadable
    '.local'             # app data/state & installed binaries, reproducible
    'go'                 # Go module cache & installed binaries, re-fetchable
    '.m2'                # Maven dependency cache, re-fetched from repos
    '.pyenv'             # pyenv Pythons, reinstallable via pyenv
    '.gradle'            # Gradle cache/wrapper, re-fetched on build
    '.ivy2'              # Ivy/SBT dependency cache, re-fetched from repos
    '.rustup'            # rustup toolchains, reinstallable via rustup
)

# ---------------------------------------------------------------------------
# Single source of truth: the backup plan.
#
# All "what to skip" logic lives here and nowhere else. We produce ONE
# NUL-separated file listing every path to back up. Each entry is either:
#   * a directory whose whole subtree is wanted (copied recursively), or
#   * an individual file living in a directory we had to split because it
#     also contains excluded content.
# A directory is split (its children listed individually) only when it
# actually contains something excluded; otherwise it is listed wholesale and
# we do not descend into it. The same plan file feeds estimation, the size
# breakdown and the final rsync, so they can never drift apart.
# ---------------------------------------------------------------------------

PLAN_FILE=$(mktemp)
trap 'rm -f "$PLAN_FILE"' EXIT

# Absolute paths that must never be backed up:
#   * directories whose name matches EXCLUDES (caches, toolchains, ...)
#   * Rust "target/" build dirs (a dir named target next to a Cargo.toml);
#     "target" alone is too generic, so we require the Cargo.toml sibling.
declare -A EXCLUDED_SET=()

detect_exclusions() {
    local base cargo_toml target_dir dir pattern
    local name_expr=()
    for pattern in "${EXCLUDES[@]}"; do
        name_expr+=(-name "$pattern" -o)
    done

    for base in "${DIRECTORIES[@]}"; do
        [[ -d "$base" ]] || continue

        # Name-matched dirs (pruned so we don't waste time inside them).
        while IFS= read -r -d '' dir; do
            EXCLUDED_SET["$dir"]=1
        done < <(find "$base" -xdev -type d \
            \( "${name_expr[@]}" -false \) -prune -print0 2>/dev/null)

        # Rust target dirs, skipping already-excluded names while searching.
        while IFS= read -r -d '' cargo_toml; do
            target_dir="$(dirname "$cargo_toml")/target"
            [[ -d "$target_dir" ]] && EXCLUDED_SET["$target_dir"]=1
        done < <(find "$base" -xdev \
            \( -type d \( "${name_expr[@]}" -false \) -prune \) -o \
            -type f -name Cargo.toml -print0 2>/dev/null)
    done
}

# Does any excluded path live strictly below this directory?
has_excluded_under() {
    local prefix="$1/" key
    for key in "${!EXCLUDED_SET[@]}"; do
        [[ "$key" == "$prefix"* ]] && return 0
    done
    return 1
}

emit_plan_entry() {
    printf '%s\0' "$1" >>"$PLAN_FILE"
}

# Add the wanted content of a directory to the plan (see header comment).
plan_dir() {
    local dir="$1" child
    [[ -n "${EXCLUDED_SET[$dir]:-}" ]] && return

    if ! has_excluded_under "$dir"; then
        emit_plan_entry "$dir"
        return
    fi

    while IFS= read -r -d '' child; do
        if [[ -d "$child" && ! -L "$child" ]]; then
            plan_dir "$child"
        else
            emit_plan_entry "$child"
        fi
    done < <(find "$dir" -xdev -mindepth 1 -maxdepth 1 -print0 2>/dev/null)
}

build_plan() {
    : >"$PLAN_FILE"
    local directory
    for directory in "${DIRECTORIES[@]}"; do
        [[ -d "$directory" ]] || continue
        plan_dir "$directory"
    done
}

# Apparent size in bytes of a single path.
du_bytes() {
    local b
    b=$(du -s -x --apparent-size --block-size=1 "$1" 2>/dev/null |
        awk '{print $1}')
    echo "${b:-0}"
}

# Size of a path as it will actually be backed up, derived purely from the
# plan so it matches the real backup exactly:
#   * if the path was split, sum the plan entries at/under it;
#   * if it sits inside a wholesale (clean) directory, du it directly;
#   * otherwise it is excluded and contributes nothing.
size_of() {
    local path="$1" prefix="$1/" entry total=0 found=0 inside=0
    while IFS= read -r -d '' entry; do
        if [[ "$entry" == "$path" || "$entry" == "$prefix"* ]]; then
            found=1
            total=$((total + $(du_bytes "$entry")))
        elif [[ "$path" == "$entry/"* ]]; then
            inside=1
        fi
    done <"$PLAN_FILE"

    if ((found)); then
        echo "$total"
    elif ((inside)); then
        du_bytes "$path"
    else
        echo 0
    fi
}

detect_exclusions
build_plan

echo
echo "========================================"
echo "Pre-backup size estimation"
echo "========================================"

# Show subdirectory breakdown for directories larger than this (10 GiB)
BREAKDOWN_THRESHOLD=$((10 * 1024 * 1024 * 1024))

# Only list subdirectories that are at least this size (1 GiB)
DISPLAY_THRESHOLD=$((1 * 1024 * 1024 * 1024))

# Print one "path  size" line and, when the entry is large enough, recurse
# into its subdirectories. Used for both top-level directories and the
# subdirectories discovered during a breakdown, so formatting and the
# descend rule stay identical everywhere.
print_entry() {
    local path="$1" size="$2"
    printf "%-30s %s\n" "$path" \
        "$(numfmt --to=iec-i --suffix=B "$size")"
    if ((size >= BREAKDOWN_THRESHOLD)); then
        show_breakdown "$path"
    fi
}

# List immediate subdirectories (>= DISPLAY_THRESHOLD) of a directory using
# plan-derived sizes, so excluded content is naturally omitted.
show_breakdown() {
    local parent="$1" child size
    while IFS= read -r -d '' child; do
        [[ -d "$child" && ! -L "$child" ]] || continue
        size=$(size_of "$child")
        ((size >= DISPLAY_THRESHOLD)) || continue
        print_entry "$child" "$size"
    done < <(find "$parent" -xdev -mindepth 1 -maxdepth 1 -print0 2>/dev/null)
}

TOTAL_BYTES=0
for directory in "${DIRECTORIES[@]}"; do
    [[ -d "$directory" ]] || continue
    SIZE=$(size_of "$directory")
    print_entry "$directory" "$SIZE"
    TOTAL_BYTES=$((TOTAL_BYTES + SIZE))
done

# Add 15% safety margin
REQUIRED_BYTES=$((TOTAL_BYTES + (TOTAL_BYTES * 15 + 99) / 100))

echo
echo "========================================"
echo "Backup size estimate"
echo "========================================"

printf "Estimated backup size : %s\n" \
    "$(numfmt --to=iec-i --suffix=B "$TOTAL_BYTES")"

printf "15%% safety margin     : %s\n" \
    "$(numfmt --to=iec-i --suffix=B "$((REQUIRED_BYTES - TOTAL_BYTES))")"

printf "Space required        : %s\n" \
    "$(numfmt --to=iec-i --suffix=B "$REQUIRED_BYTES")"

# Available destination space (only when a destination was given)
if [[ -n "$DEST" ]]; then
    AVAILABLE_BYTES=$(df -B1 --output=avail "$DEST" | awk 'NR==2 {print $1}')
    printf "Available disk space  : %s\n" \
        "$(numfmt --to=iec-i --suffix=B "$AVAILABLE_BYTES")"
fi

echo "========================================"

# In estimate-only mode, stop here without touching the destination.
if [[ $ONLY_ESTIMATE -eq 1 ]]; then
    exit 0
fi

# Refuse to proceed if insufficient space
if ((AVAILABLE_BYTES < REQUIRED_BYTES)); then
    echo
    echo "ERROR: Insufficient free space on backup destination."
    echo "Free up space or choose another destination."
    exit 1
fi

echo
read -r -p "Proceed with backup? [y/N]: " CONFIRM

case "${CONFIRM,,}" in
y | yes)
    echo "Proceeding with backup..."
    ;;
*)
    echo "Backup cancelled by user."
    exit 0
    ;;
esac

# Create backup directory only after confirmation
BACKUP="$DEST/ubuntu-preupgrade-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP"
chmod 700 "$BACKUP"

exec > >(tee -a "$BACKUP/backup.log") 2>&1

echo "========================================"
echo "Ubuntu pre-upgrade backup"
echo "Destination: $BACKUP"
echo "Started: $(date)"
echo "========================================"

RSYNC_OPTS=(
    -aHAX
    --numeric-ids
    --human-readable
    --info=progress2
    --from0
    --files-from="$PLAN_FILE"
    # --files-from turns off -a's recursion unless --recursive is given
    # explicitly; wholesale directories in the plan must be copied in full.
    --recursive
)

echo
echo "Backing up all planned paths..."

# Plan entries are absolute paths, so using "/" as the source recreates the
# full tree under $BACKUP (e.g. /home/u -> $BACKUP/home/u). The plan already
# omits every excluded path, so no --exclude filters are needed here.
rsync "${RSYNC_OPTS[@]}" / "$BACKUP/"

# Collect system and package inventories
REPORT="$BACKUP/inventory"
mkdir -p "$REPORT"

echo "Collecting system inventory..."

lsb_release -a >"$REPORT/ubuntu-version.txt" 2>&1 || true
uname -a >"$REPORT/kernel.txt"
lsblk -f >"$REPORT/disks.txt"
findmnt >"$REPORT/mounts.txt"
lspci -nnk >"$REPORT/hardware.txt"
dpkg-query -W -f='${binary:Package}\t${Version}\n' \
    >"$REPORT/installed-packages.txt"
apt-mark showmanual >"$REPORT/manual-packages.txt"
apt-mark showhold >"$REPORT/held-packages.txt"
apt-mark showauto >"$REPORT/automatic-packages.txt"
apt-cache policy >"$REPORT/apt-policy.txt"

snap list >"$REPORT/snap-packages.txt" 2>&1 || true
flatpak list --system >"$REPORT/flatpak-packages.txt" 2>&1 || true

if command -v efibootmgr >/dev/null; then
    efibootmgr -v >"$REPORT/efi-boot-entries.txt" 2>&1 || true
fi

# Save backup metadata
date -Is >"$REPORT/backup-date.txt"
df -h >"$REPORT/disk-space.txt"

sync

echo
echo "========================================"
echo "BACKUP COMPLETED"
echo "Location: $BACKUP"
echo "Finished: $(date)"
echo "========================================"

du -sh "$BACKUP"
