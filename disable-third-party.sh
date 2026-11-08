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

# Official Ubuntu repository hosts that must NOT be disabled.
UBUNTU_HOSTS_RE='([a-z0-9.-]+\.)?(archive\.ubuntu\.com|security\.ubuntu\.com|ports\.ubuntu\.com|ubuntu\.com)'

# A file is considered "official Ubuntu" if every active repository URI in it
# points at an official Ubuntu host. Such files are left untouched.
is_official_ubuntu() {
    local file="$1"
    local uris

    # Collect URIs from both deb822 (URIs:) and legacy (deb ... http://...) formats.
    uris="$(grep -ihoE 'https?://[^ ]+' "$file" || true)"

    # No URIs at all -> don't treat as official (be safe, let caller decide).
    [[ -z "$uris" ]] && return 1

    # If any URI is NOT an official Ubuntu host, it's third-party.
    while IFS= read -r uri; do
        [[ -z "$uri" ]] && continue
        if ! echo "$uri" | grep -qiE "^https?://${UBUNTU_HOSTS_RE}(/|:|$)"; then
            return 1
        fi
    done <<<"$uris"

    return 0
}

# Disable legacy .list repositories
find "$DIR" -maxdepth 1 -type f -name '*.list' -print0 |
    while IFS= read -r -d '' file; do
        if is_official_ubuntu "$file"; then
            echo "Skipping official Ubuntu source: $file"
            continue
        fi
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
        if is_official_ubuntu "$file"; then
            echo "Skipping official Ubuntu source: $file"
            continue
        fi
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
