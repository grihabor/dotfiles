#!/usr/bin/env bash
set -euo pipefail

DIR="/etc/apt/sources.list.d"
BACKUP="/root/apt-sources-backup-$(date +%Y%m%d-%H%M%S)"

if [[ $EUID -ne 0 ]]; then
    echo "Run with sudo: sudo $0"
    exit 1
fi

mkdir -p "$BACKUP"
cp -a "$DIR/." "$BACKUP/"

echo "Backup created: $BACKUP"

# Disable legacy .list repositories
find "$DIR" -maxdepth 1 -type f -name '*.list' -print0 |
    while IFS= read -r -d '' file; do
        if grep -qE '^[[:space:]]*deb(-src)?[[:space:]]' "$file"; then
            echo "Disabling: $file"
            sed -i -E \
                's/^([[:space:]]*deb(-src)?[[:space:]])/# DISABLED FOR DIST UPGRADE: \1/' \
                "$file"
        fi
    done

# Disable modern deb822 .sources repositories
find "$DIR" -maxdepth 1 -type f -name '*.sources' -print0 |
    while IFS= read -r -d '' file; do
        if grep -qE '^Types:' "$file"; then
            echo "Disabling: $file"
            if grep -qE '^Enabled:' "$file"; then
                sed -i -E 's/^Enabled:.*/Enabled: no/' "$file"
            else
                sed -i '/^Types:/i Enabled: no' "$file"
            fi
        fi
    done

echo
echo "Done. Third-party source files disabled."
echo "Original files saved in: $BACKUP"

apt-get update
