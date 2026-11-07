#!/usr/bin/env bash
set -Eeuo pipefail

# Usage: sudo ./ubuntu-preupgrade-backup.sh /media/username/BackupDrive

if [[ $EUID -ne 0 ]]; then
    echo "ERROR: Run with sudo."
    exit 1
fi

if [[ $# -ne 1 || ! -d "$1" ]]; then
    echo "Usage: sudo $0 /path/to/external/drive"
    exit 1
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

command -v rsync >/dev/null || {
    echo "Install rsync first: sudo apt install rsync"
    exit 1
}

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

    if [[ "$source" == "/home" ]]; then
        rsync "${RSYNC_OPTS[@]}" \
            --exclude='/.cache/***' \
            --exclude='*/.cache/***' \
            "$source/" "$BACKUP/$relative/"
    else
        rsync "${RSYNC_OPTS[@]}" \
            "$source/" "$BACKUP/$relative/"
    fi
}

# System configuration and user data
for directory in \
    /etc \
    /home \
    /root \
    /usr/local \
    /opt \
    /boot \
    /var/lib/dpkg \
    /var/lib/apt \
    /var/lib/snapd \
    /var/lib/flatpak \
    /var/lib/NetworkManager \
    /var/lib/bluetooth \
    /var/lib/AccountsService \
    /var/lib/systemd \
    /var/spool/cron; do
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
