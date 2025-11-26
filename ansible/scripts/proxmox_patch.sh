#!/bin/bash

# Proxmox patching wrapper

PLAYBOOK_DIR="/home/aman/git/homelab-infra-priv/ansible/playbooks"
LOG_DIR="/home/aman/git/homelab-infra-priv/ansible/logs/proxmox"
TIMESTAMP=$(date +%Y%m%dT%H%M%S)
LOG_FILE="$LOG_DIR/cron_proxmox_patch_$TIMESTAMP.log"

mkdir -p "$LOG_DIR"

echo "[$(date +%Y-%m-%dT%H:%M:%S)] Starting Proxmox patch run..." >> "$LOG_FILE"

ansible-playbook -i ../inventory/hosts.ini "$PLAYBOOK_DIR/proxmox.yml" >> "$LOG_FILE" 2>&1

echo "[$(date +%Y-%m-%dT%H:%M:%S)] Proxmox patch run finished." >> "$LOG_FILE"
