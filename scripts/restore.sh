#!/usr/bin/env bash
# Restore a backup created by the backup service.
#
# Usage:
#   scripts/restore.sh                 # list available backups
#   scripts/restore.sh <backup-file>   # restore that backup
#
# The current server data is not deleted: it is moved to data.before-restore-<date>/
# so a restore can always be undone.
set -euo pipefail

cd "$(dirname "$0")/.."

if [ $# -eq 0 ]; then
    echo "Available backups (newest first):"
    ls -1t backups/*.tar.gz 2>/dev/null || echo "  none yet"
    echo
    echo "Usage: $0 backups/<file>.tar.gz"
    exit 0
fi

backup="$1"
if [ ! -f "$backup" ]; then
    echo "Backup not found: $backup" >&2
    exit 1
fi

read -r -p "Restore $backup? The server will be stopped for a moment. [y/N] " answer
if [[ "$answer" != [yY] ]]; then
    echo "Cancelled."
    exit 0
fi

echo "Stopping the server..."
docker compose stop backup minecraft

old="data.before-restore-$(date +%Y%m%d-%H%M%S)"
echo "Moving current data to $old/"
mv data "$old"
mkdir data

echo "Extracting $backup..."
tar -xzf "$backup" -C data

# Server files that are not in the backup (server jar, libraries, cache)
# are downloaded again automatically when the container starts.
echo "Starting the server..."
docker compose up -d

echo "Done. If everything works, you can delete $old/"
