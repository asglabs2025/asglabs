#!/bin/bash
# ----------------------------------------------------------------------
# Proxmox ZFS + OS Backup Script (Flat Snapshot Layout)
# - Versioned snapshots via rsync --link-dest
# - ZFS validation
# - Lock protection
# - Retention cleanup
# - Optional ZFS snapshot of backup dataset
# ----------------------------------------------------------------------

set -euo pipefail

# ---------------- CONFIG ----------------
ZFS_POOL="data"
BACKUP_DATASET="data/infra_backups"
SNAPSHOT_ROOT="/data/infra_backups/proxmox"
LOG_DIR="/var/log/rsync"
RETENTION_DAYS=7
DATE=$(date +%F)
LOG_FILE="$LOG_DIR/rsync-backup-$DATE.log"
LOCKFILE="/var/run/proxmox-backup.lock"
# ----------------------------------------

# ---------------- LOCKING ----------------
exec 9>"$LOCKFILE"
flock -n 9 || {
    echo "Backup already running. Exiting."
    exit 1
}
# -----------------------------------------

# ---------------- LOGGING ----------------
timestamp() { date "+%F %T"; }
log() { echo "$(timestamp) - $*" | tee -a "$LOG_FILE"; }
# -----------------------------------------

mkdir -p "$LOG_DIR"

log "===== Starting backup for $DATE ====="

# ---------------- VALIDATE ZFS ----------------
if ! zfs list "$ZFS_POOL" >/dev/null 2>&1; then
    log "ERROR: ZFS pool '$ZFS_POOL' not available. Aborting."
    exit 1
fi

if ! zfs list "$BACKUP_DATASET" >/dev/null 2>&1; then
    log "ERROR: Backup dataset '$BACKUP_DATASET' not available. Aborting."
    exit 1
fi

log "ZFS pool and dataset verified."
# ---------------------------------------------

mkdir -p "$SNAPSHOT_ROOT"

# ---------------- CREATE TODAY SNAPSHOT DIR ----------------
TODAY="$SNAPSHOT_ROOT/$DATE"
mkdir -p "$TODAY"
log "Snapshot directory: $TODAY"
# ------------------------------------------------------------

# ---------------- FIND PREVIOUS SNAPSHOT ----------------
PREV=$(find "$SNAPSHOT_ROOT" -maxdepth 1 -type d -name "20*-*-*" \
       ! -name "$DATE" -printf "%f\n" | sort | tail -n1 || true)

if [ -n "$PREV" ]; then
    LINK_DEST="$SNAPSHOT_ROOT/$PREV"
    log "Previous snapshot detected: $LINK_DEST"
else
    LINK_DEST=""
    log "No previous snapshot found — full backup."
fi
# ---------------------------------------------------------

# ---------------- RSYNC OPTIONS ----------------
RSYNC_OPTS_CONFIG="-aHAX --numeric-ids --delete --stats"
RSYNC_OPTS_LARGE="-aHAX --numeric-ids --partial --inplace --delete --stats"

if [ -n "$LINK_DEST" ]; then
    RSYNC_OPTS_CONFIG="$RSYNC_OPTS_CONFIG --link-dest=$LINK_DEST"
    RSYNC_OPTS_LARGE="$RSYNC_OPTS_LARGE --link-dest=$LINK_DEST"
fi
# ----------------------------------------------

# ---------------- CREATE STRUCTURE ----------------
for dir in isos share templates cloud_images scripts etc root; do
    mkdir -p "$TODAY/$dir"
done
# -------------------------------------------------

# ---------------- BACKUP ZFS DATASETS ----------------
declare -A DATASETS=(
    [isos]="/data/isos/"
    [share]="/data/share/"
    [templates]="/data/templates/"
    [cloud_images]="/data/cloud_images/"
)

for name in "${!DATASETS[@]}"; do
    SRC="${DATASETS[$name]}"
    DEST="$TODAY/$name/"
    log "Backing up $SRC → $DEST"
    rsync $RSYNC_OPTS_LARGE "$SRC" "$DEST" 2>&1 | tee -a "$LOG_FILE"
done
# -----------------------------------------------------

# ---------------- BACKUP SCRIPTS ----------------
log "Backing up /usr/local/bin/*.sh"
rsync $RSYNC_OPTS_CONFIG /usr/local/bin/*.sh "$TODAY/scripts/" 2>&1 | tee -a "$LOG_FILE"
# -----------------------------------------------

# ---------------- BACKUP /etc ----------------
log "Backing up /etc"
rsync $RSYNC_OPTS_CONFIG /etc/ "$TODAY/etc/" 2>&1 | tee -a "$LOG_FILE"
# ---------------------------------------------

# ---------------- BACKUP /root ----------------
log "Backing up /root"
rsync $RSYNC_OPTS_CONFIG /root/ "$TODAY/root/" 2>&1 | tee -a "$LOG_FILE"
# ----------------------------------------------

# ---------------- ROTATE OLD SNAPSHOTS ----------------
log "Rotating snapshots older than $RETENTION_DAYS days"
CUTOFF=$(date -d "$RETENTION_DAYS days ago" +%s)

for snapshot in "$SNAPSHOT_ROOT"/*; do
    [ -d "$snapshot" ] || continue
    SNAPSHOT_DATE=$(basename "$snapshot")
    [[ ! "$SNAPSHOT_DATE" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] && continue
    SNAPSHOT_SEC=$(date -d "$SNAPSHOT_DATE" +%s 2>/dev/null || continue)

    if (( SNAPSHOT_SEC < CUTOFF )); then
        rm -rf "$snapshot"
        log "Deleted old snapshot: $snapshot"
    fi
done
# ------------------------------------------------------

# ---------------- ROTATE OLD ZFS SNAPSHOTS ----------------
log "Rotating ZFS snapshots older than $RETENTION_DAYS days"
CUTOFF=$(date -d "$RETENTION_DAYS days ago" +%s)

while IFS= read -r snap; do
    SNAP_DATE="${snap##*@backup-}"
    [[ ! "$SNAP_DATE" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] && continue
    SNAP_SEC=$(date -d "$SNAP_DATE" +%s 2>/dev/null || continue)

    if (( SNAP_SEC < CUTOFF )); then
        if zfs destroy "$snap"; then
            log "Deleted old ZFS snapshot: $snap"
        else
            log "WARNING: Failed to destroy ZFS snapshot: $snap (continuing)"
        fi
    fi
done < <(zfs list -t snapshot -H -o name "$BACKUP_DATASET")
# ----------------------------------------------------------

# ---------------- ZFS SNAPSHOT ----------------
zfs snapshot "$BACKUP_DATASET@backup-$DATE"
log "Created ZFS snapshot: $BACKUP_DATASET@backup-$DATE"
# --------------------------------------------------------

log "===== Backup completed successfully ====="
log "Snapshot stored at $TODAY"