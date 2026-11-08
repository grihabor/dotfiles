#!/usr/bin/env bash
set -Eeuo pipefail

# Usage:
#   sudo ./ubuntu-preupgrade-backup.sh /media/username/BackupDrive
#   sudo ./ubuntu-preupgrade-backup.sh            # choose drive interactively
#   sudo ./ubuntu-preupgrade-backup.sh --only-estimate-size [/path]

usage() {
    echo "Usage: sudo $0 [--only-estimate-size] [--keep-plan] [/path/to/external/drive]"
    echo "       sudo $0 --only-estimate-size [--keep-plan]"
    echo
    echo "  If no destination path is given for a real backup, you will be"
    echo "  prompted to choose a mounted drive and a subdirectory on it."
    echo
    echo "  --keep-plan  Write the NUL-separated backup plan to a readable"
    echo "               file and keep it after exit (path is printed)."
    exit 1
}

# Progress messages go to stderr so they never mix into the plan/estimate
# output on stdout. Each line is timestamped so a long pause is obvious.
log() {
    printf '[%s] %s\n' "$(date +%H:%M:%S)" "$*" >&2
}

if [[ $EUID -ne 0 ]]; then
    echo "ERROR: Run with sudo."
    exit 1
fi

# Parse options; collect positional arguments separately.
ONLY_ESTIMATE=0
KEEP_PLAN=0
POSITIONAL=()
for arg in "$@"; do
    case "$arg" in
    --only-estimate-size) ONLY_ESTIMATE=1 ;;
    --keep-plan) KEEP_PLAN=1 ;;
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
# When omitted for a real backup, it is chosen interactively below.
if [[ $# -gt 1 ]]; then
    usage
fi

# Validate a candidate destination path and echo its canonical form.
# Enforces: it must exist, live on a separate mounted filesystem (not /)
# and not be inside /home.
validate_dest() {
    local candidate="$1" dest mount
    if [[ ! -d "$candidate" ]]; then
        echo "ERROR: Not a directory: $candidate" >&2
        return 1
    fi

    dest=$(realpath -e -- "$candidate")
    mount=$(findmnt -n -o TARGET -T "$dest")

    # Protect against accidentally backing up onto the system disk.
    if [[ "$mount" == "/" ]]; then
        echo "ERROR: Destination is not on a separate mounted filesystem." >&2
        return 1
    fi

    case "$dest/" in
    /home/*)
        echo "ERROR: Backup destination must not be inside /home." >&2
        return 1
        ;;
    esac

    printf '%s\n' "$dest"
}

# Interactively choose a mounted external drive, then a subdirectory within
# it. Prints the chosen destination path on stdout; all prompts go to stderr
# so they never contaminate the result.
select_destination() {
    local -a mounts=() labels=()
    local target source size label line

    # List mounted filesystems under the usual removable-media roots.
    while IFS=$'\t' read -r target source size label; do
        case "$target" in
        /media/* | /mnt/* | /run/media/*)
            mounts+=("$target")
            labels+=("$target  [${label:-$source}, ${size:-?}]")
            ;;
        esac
    done < <(findmnt -rn -o TARGET,SOURCE,SIZE,LABEL)

    if [[ ${#mounts[@]} -eq 0 ]]; then
        echo "ERROR: No mounted external drives found under /media, /mnt or /run/media." >&2
        return 1
    fi

    echo "Available drives:" >&2
    local i
    for i in "${!mounts[@]}"; do
        printf "  %2d) %s\n" "$((i + 1))" "${labels[$i]}" >&2
    done

    local choice drive
    while true; do
        read -r -p "Select a drive [1-${#mounts[@]}]: " choice </dev/tty
        if [[ "$choice" =~ ^[0-9]+$ ]] &&
            ((choice >= 1 && choice <= ${#mounts[@]})); then
            drive="${mounts[$((choice - 1))]}"
            break
        fi
        echo "Invalid selection." >&2
    done

    # Offer existing subdirectories plus options to use the drive root or
    # create a new subdirectory.
    local -a subdirs=()
    while IFS= read -r line; do
        subdirs+=("$line")
    done < <(find "$drive" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null | sort)

    echo >&2
    echo "Destination inside $drive:" >&2
    printf "  %2d) %s\n" 0 "(use drive root: $drive)" >&2
    for i in "${!subdirs[@]}"; do
        printf "  %2d) %s\n" "$((i + 1))" "${subdirs[$i]}/" >&2
    done
    printf "  %2s) %s\n" "n" "(create a new subdirectory)" >&2

    local sub dest name
    while true; do
        read -r -p "Select a destination [0-${#subdirs[@]}, or n]: " sub </dev/tty
        if [[ "$sub" == "n" || "$sub" == "N" ]]; then
            read -r -p "New subdirectory name: " name </dev/tty
            if [[ -z "$name" || "$name" == */* ]]; then
                echo "Invalid name." >&2
                continue
            fi
            dest="$drive/$name"
            mkdir -p "$dest" || {
                echo "ERROR: Could not create $dest" >&2
                continue
            }
            break
        elif [[ "$sub" == "0" ]]; then
            dest="$drive"
            break
        elif [[ "$sub" =~ ^[0-9]+$ ]] &&
            ((sub >= 1 && sub <= ${#subdirs[@]})); then
            dest="$drive/${subdirs[$((sub - 1))]}"
            break
        fi
        echo "Invalid selection." >&2
    done

    printf '%s\n' "$dest"
}

DEST=""
if [[ $# -eq 1 ]]; then
    DEST=$(validate_dest "$1") || exit 1
elif [[ $ONLY_ESTIMATE -eq 0 ]]; then
    # No path given for a real backup: choose one interactively.
    DEST=$(select_destination) || exit 1
    DEST=$(validate_dest "$DEST") || exit 1
    echo "Selected destination: $DEST"
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
    '__pycache__'        # Python bytecode cache, regenerated on run
    '.venv'              # Python virtualenvs, recreatable from requirements
    '.wine'              # Wine prefix, reinstallable
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
if [[ $KEEP_PLAN -eq 1 ]]; then
    # Keep the plan for inspection. Write a readable (newline-separated) copy
    # to a predictable path in the invoking user's current directory, owned by
    # that user rather than root, so it is easy to find after a sudo run.
    PLAN_KEEP="$PWD/ubuntu-preupgrade-plan.txt"
    keep_plan() {
        tr '\0' '\n' <"$PLAN_FILE" >"$PLAN_KEEP" || return
        [[ -n "${SUDO_USER:-}" ]] && chown "$SUDO_USER" "$PLAN_KEEP" 2>/dev/null
        rm -f "$PLAN_FILE"
        echo "Backup plan kept at: $PLAN_KEEP"
    }
    trap keep_plan EXIT
else
    trap 'rm -f "$PLAN_FILE"' EXIT
fi

# The plan (the single source of truth, see header comment above) is produced
# by a fast C helper that lives next to this script. It discovers excluded
# paths and emits the NUL-separated plan in a single filesystem walk. The pure
# Bash implementation this replaces was far too slow on large home trees.
#
# The helper is a self-compiling C "script": its shebang runs c-script, which
# compiles it (with mtime-based caching) and execs the result. We invoke
# c-script explicitly rather than relying on the shebang so it works under
# sudo's restricted PATH too.
#
# Exclusion rules passed to the helper:
#   * --exclude NAME     a directory whose basename equals NAME (EXCLUDES)
#   * --marker FILE:DIR  exclude sibling DIR when a dir contains file FILE:
#       Cargo.toml -> sibling "target/" (Rust build dir)
#       pants.toml -> sibling "dist/"   (Pants build dir)
# "target"/"dist" alone are too generic, hence the marker-file requirement.

# Locate the c-script interpreter. Like fd, a user-installed c-script in the
# invoking user's profile is not on PATH under sudo, so probe there too.
find_c_script() {
    local dir home
    if command -v c-script >/dev/null; then
        command -v c-script
        return 0
    fi
    home=$(eval echo "~${SUDO_USER:-}")
    for dir in "$home/.local/bin" "$home/.nix-profile/bin" "$home/.cargo/bin"; do
        if [[ -x "$dir/c-script" ]]; then
            echo "$dir/c-script"
            return 0
        fi
    done
    return 1
}

if ! C_SCRIPT=$(find_c_script); then
    echo "ERROR: c-script not found (needed to build the plan helper)."
    echo "(ensure c-script is on PATH, incl. when running under sudo)"
    exit 1
fi

# The plan and size helper sources live next to c-script.
HELPER_DIR="$(dirname -- "$C_SCRIPT")"
PLAN_SRC="$HELPER_DIR/ubuntu-preupgrade-plan.c"
SIZE_SRC="$HELPER_DIR/ubuntu-preupgrade-size.c"

if [[ ! -f "$PLAN_SRC" ]]; then
    echo "ERROR: plan helper source not found: $PLAN_SRC"
    exit 1
fi
if [[ ! -f "$SIZE_SRC" ]]; then
    echo "ERROR: size helper source not found: $SIZE_SRC"
    exit 1
fi

build_plan() {
    local directory dirs=() args=() pattern
    for directory in "${DIRECTORIES[@]}"; do
        [[ -d "$directory" ]] && dirs+=("$directory")
    done

    for pattern in "${EXCLUDES[@]}"; do
        args+=(--exclude "$pattern")
    done
    args+=(--marker Cargo.toml:target --marker pants.toml:dist)

    # The helper logs progress to stderr and writes the plan to stdout.
    "$C_SCRIPT" "$PLAN_SRC" "${args[@]}" -- "${dirs[@]}" >"$PLAN_FILE"
}

build_plan

echo
echo "========================================"
echo "Pre-backup size estimation"
echo "========================================"

# Show subdirectory breakdown for directories larger than this (10 GiB)
BREAKDOWN_THRESHOLD=$((10 * 1024 * 1024 * 1024))

# Only list subdirectories that are at least this size (1 GiB)
DISPLAY_THRESHOLD=$((1 * 1024 * 1024 * 1024))

# The size estimation (like the plan) is produced by a fast C helper. Reading
# the plan file once in Bash and shelling out to `du` per entry was far too
# slow; the helper measures every planned path in a single filesystem walk and
# answers all size queries from a sorted index. It emits "<bytes>\t<path>"
# lines (top-level directories plus the large-subdirectory breakdown) on
# stdout and a final "<total>\tTOTAL" line, logging progress to stderr.
log "Estimating backup size (this can take a while on large trees)..."
TOTAL_BYTES=0
while IFS=$'\t' read -r bytes path; do
    if [[ "$path" == TOTAL ]]; then
        TOTAL_BYTES=$bytes
        continue
    fi
    printf "%-30s %s\n" "$path" \
        "$(numfmt --to=iec-i --suffix=B "$bytes")"
done < <("$C_SCRIPT" "$SIZE_SRC" \
    --plan "$PLAN_FILE" \
    --breakdown-threshold "$BREAKDOWN_THRESHOLD" \
    --display-threshold "$DISPLAY_THRESHOLD" \
    -- "${DIRECTORIES[@]}")

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
