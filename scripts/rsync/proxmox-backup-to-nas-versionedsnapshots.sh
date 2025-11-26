#!/bin/bash
# ----------------------------------------------------------------------
# Proxmox ZFS + Config Backup Script to iSCSI NAS (Versioned Snapshots)
# Logs all output with timestamps
# Uses rsync --link-dest for daily snapshot backups
# Automatically deletes snapshots older than 14 days
# ----------------------------------------------------------------------

set -euo pipefail

# --- Config ---
MOUNT_POINT="/mnt/NASproxmoxconfigiSCSI"
SNAPSHOT_ROOT="$MOUNT_POINT/backups"
LOG_DIR="/var/log/rsync"
DATE=$(date +%F)
LOG_FILE="$LOG_DIR/rsync-backup-$DATE.log"
RETENTION_DAYS=14

mkdir -p "$LOG_DIR"
mkdir -p "$SNAPSHOT_ROOT"

# --- Logging functions ---
timestamp() { date "+%F %T"; }
log() { echo "$(timestamp) - $*" | tee -a "$LOG_FILE"; }

# --- Ensure mount is available ---
log "Checking if $MOUNT_POINT is mounted..."
if ! mountpoint -q "$MOUNT_POINT"; then
    log "$MOUNT_POINT not mounted. Attempting to mount..."
    mount "$MOUNT_POINT" || { log "ERROR: Failed to mount $MOUNT_POINT"; exit 1; }
    log "$MOUNT_POINT successfully mounted."
fi

# --- Create today's snapshot directory ---
TODAY="$SNAPSHOT_ROOT/$DATE"
mkdir -p "$TODAY"
log "Today's snapshot directory: $TODAY"

# --- Find the previous snapshot for --link-dest ---
PREV=$(ls -1 $SNAPSHOT_ROOT | grep -v "$DATE" | tail -n1 || true)
if [ -n "$PREV" ]; then
    LINK_DEST="$SNAPSHOT_ROOT/$PREV"
    log "Previous snapshot found: $LINK_DEST"
else
    LINK_DEST=""
    log "No previous snapshot found, this will be a full backup."
fi

# --- Rsync options ---
RSYNC_OPTS="-avh --partial --inplace --stats --delete"
if [ -n "$LINK_DEST" ]; then
    RSYNC_OPTS="$RSYNC_OPTS --link-dest=$LINK_DEST"
fi

# --- Create backup directories ---
for dir in hdd/isos hdd/share hdd/templates hdd/scripts hdd/pve-config hdd/pve-extra-config; do
    mkdir -p "$TODAY/$dir"
done

# --- Backup HDD datasets ---
declare -A DATASETS=(
    [isos]="/hdd/isos/"
    [share]="/hdd/share/"
    [templates]="/hdd/templates/"
)

for name in "${!DATASETS[@]}"; do
    SRC="${DATASETS[$name]}"
    DEST="$TODAY/hdd/$name/"
    log "=== Backing up $SRC to $DEST ==="
    rsync $RSYNC_OPTS "$SRC" "$DEST" 2>&1 | tee -a "$LOG_FILE"
done

# --- Backup backup script itself ---
log "=== Backing up backup script ==="
rsync $RSYNC_OPTS /usr/local/bin/backup-to-nas.sh "$TODAY/hdd/scripts/" 2>&1 | tee -a "$LOG_FILE"

# --- Backup Proxmox config (excluding VM & CT configs) ---
log "=== Backing up /etc/pve excluding qemu-server & lxc directories ==="
rsync $RSYNC_OPTS --exclude='qemu-server/' --exclude='lxc/' /etc/pve/ "$TODAY/hdd/pve-config/" 2>&1 | tee -a "$LOG_FILE"

# --- Backup extra Proxmox configs ---
log "=== Backing up network & SSH configs ==="
rsync $RSYNC_OPTS /etc/network/interfaces /etc/hosts /etc/fstab /root/.ssh/ /etc/ssh/ "$TODAY/hdd/pve-extra-config/" 2>&1 | tee -a "$LOG_FILE"

# --- Rotate old snapshots ---
log "=== Rotating snapshots older than $RETENTION_DAYS days ==="
find "$SNAPSHOT_ROOT" -maxdepth 1 -mindepth 1 -type d -mtime +$RETENTION_DAYS -exec rm -rf {} \; -exec echo "Deleted old snapshot: {}" \; | tee -a "$LOG_FILE"

log "=== Backup completed successfully ==="
log "Snapshot for $DATE stored at $TODAY"
