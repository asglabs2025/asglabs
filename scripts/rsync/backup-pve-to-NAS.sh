#!/bin/bash
# ----------------------------------------------------------------------
# Proxmox Host Configuration Backup Script (TrueNAS NFS Target)
# - Backs up ONLY Proxmox configuration and system files
# - No VM disks, no ZFS, no application data
# - Designed for TrueNAS-backed storage (NFS)
# ----------------------------------------------------------------------

set -euo pipefail

# ---------------- CONFIG ----------------
BACKUP_ROOT="/mnt/pve/infra_backups/proxmox"
DATE=$(date +%F)
TARGET="$BACKUP_ROOT/$DATE"
LOG_DIR="/var/log/proxmox-config-backup"
LOG_FILE="$LOG_DIR/backup-$DATE.log"
LOCKFILE="/var/run/proxmox-config-backup.lock"
RETENTION_DAYS=14
# ----------------------------------------

# ---------------- LOCKING ----------------
exec 9>"$LOCKFILE"
flock -n 9 || {
    echo "Backup already running. Exiting."
    exit 1
}
# ----------------------------------------

# ---------------- LOGGING ----------------
mkdir -p "$LOG_DIR"
log() { echo "$(date '+%F %T') - $*" | tee -a "$LOG_FILE"; }
# ----------------------------------------

log "===== Starting Proxmox config backup ====="

# ---------------- CHECK TARGET ----------------
if [ ! -d "$BACKUP_ROOT" ]; then
    log "ERROR: Backup target not mounted: $BACKUP_ROOT"
    exit 1
fi

mkdir -p "$TARGET"
log "Backup target: $TARGET"
# ---------------------------------------------

# ---------------- BACKUP /etc/pve ----------------
log "Backing up /etc/pve (VM + cluster config)"
rsync -aHAX --delete /etc/pve/ "$TARGET/etc-pve/" | tee -a "$LOG_FILE"
# -----------------------------------------------

# ---------------- BACKUP NETWORK CONFIG ----------------
log "Backing up network configuration"
rsync -aHAX /etc/network/ "$TARGET/network/" | tee -a "$LOG_FILE"
cp /etc/hosts "$TARGET/hosts" 2>/dev/null || true
cp /etc/resolv.conf "$TARGET/resolv.conf" 2>/dev/null || true
# ------------------------------------------------------

# ---------------- BACKUP SYSTEM CONFIG ----------------
log "Backing up system configuration"
cp -a /etc/fstab "$TARGET/fstab" 2>/dev/null || true
cp -a /etc/sysctl.conf "$TARGET/sysctl.conf" 2>/dev/null || true
# -----------------------------------------------------

# ---------------- BACKUP USER SCRIPTS ----------------
log "Backing up scripts and root configs"
rsync -a /usr/local/bin/ "$TARGET/scripts/" 2>&1 | tee -a "$LOG_FILE"
rsync -a /root/ "$TARGET/root/" 2>&1 | tee -a "$LOG_FILE"
# -----------------------------------------------------

# ---------------- BACKUP CRON JOBS ----------------
log "Backing up cron configuration"
rsync -a /etc/cron.* "$TARGET/cron/" 2>&1 | tee -a "$LOG_FILE"
# --------------------------------------------------

# ---------------- CLEAN OLD BACKUPS ----------------
log "Cleaning backups older than $RETENTION_DAYS days"
find "$BACKUP_ROOT" -maxdepth 1 -type d -name "20*" \
    -mtime +"$RETENTION_DAYS" -exec rm -rf {} \; 2>/dev/null || true
# ---------------------------------------------------

log "===== Backup completed successfully ====="
log "Stored at: $TARGET"