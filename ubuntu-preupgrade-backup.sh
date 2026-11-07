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

# Build tool-specific exclude arguments from the single EXCLUDES list so
# estimation (du) and backup (rsync) always stay in sync.
DU_EXCLUDES=()
RSYNC_EXCLUDES=()
for pattern in "${EXCLUDES[@]}"; do
    DU_EXCLUDES+=(--exclude="$pattern")
    # Anchored form matches at the source root, '**/' form at any depth.
    RSYNC_EXCLUDES+=(--exclude="$pattern" --exclude="**/$pattern")
done

echo
echo "========================================"
echo "Pre-backup size estimation"
echo "========================================"

TOTAL_BYTES=0

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

# List immediate subdirectories (>= DISPLAY_THRESHOLD) of a directory and
# hand each to print_entry. du prints a directory once its traversal
# completes, so output appears incrementally.
show_breakdown() {
    local parent="$1"
    local subsize subdir
    while IFS=$'\t' read -r subsize subdir; do
        [[ "$subdir" == "$parent" ]] && continue
        ((subsize >= DISPLAY_THRESHOLD)) || continue
        print_entry "$subdir" "$subsize"
    done < <(du -x --apparent-size --block-size=1 "${DU_EXCLUDES[@]}" \
        --max-depth=1 "$parent" 2>/dev/null)
}

for directory in "${DIRECTORIES[@]}"; do
    if [[ ! -d "$directory" ]]; then
        continue
    fi

    SIZE=$(du -sx --apparent-size --block-size=1 "${DU_EXCLUDES[@]}" \
        "$directory" | awk '{print $1}')

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
)

backup_tree() {
    local source="$1"
    local relative="${source#/}"

    if [[ ! -d "$source" ]]; then
        echo "Skipping missing directory: $source"
        return
    fi

    echo
    echo "Backing up $source"

    mkdir -p "$BACKUP/$relative"

    rsync "${RSYNC_OPTS[@]}" "${RSYNC_EXCLUDES[@]}" \
        "$source/" "$BACKUP/$relative/"
}

# System configuration and user data (same list used for estimation)
for directory in "${DIRECTORIES[@]}"; do
    backup_tree "$directory"
done

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
