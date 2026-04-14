#!/bin/bash
LOGFILE="/home/user/logs/crontab_logs/bpverify/bpverify_cron_$(date +%F).log"
exec >> "$LOGFILE" 2>&1
# =============================================================================
# NetBackup Automated Verification Script
# Author  : Aman Ghattaoraya
# Purpose : Randomly selects one policy from each of the two policy list files
#           (fileservers and others), confirms a valid backup image exists
#           for the previous calendar month, then runs a single bpverify job
#           per policy — producing 2 outputs structured to dated .txt report files.
#
# Policy files:
#   /home/user/policies_fileservers.txt  -> 1 random policy, start-of-month window
#   /home/user/policies_other.txt        -> 1 random policy, end-of-month window
#
# Output logs:
#   /home/user/logs/<Month_YYYY>/POLICYNAME_MMDDYYYY.txt
#
# Exactly 2 bpverify jobs are run per execution (one per file).
#
# Cron (1st of each month at 06:00):
#   0 6 1 * * /home/user/bpverify_new.sh
# =============================================================================
 
BPIMAGELIST="/usr/openv/netbackup/bin/admincmd/bpimagelist"
BPVERIFY="/usr/openv/netbackup/bin/admincmd/bpverify"
 
POLICY_FILE_FILESERVERS="/home/user/policies_fileservers.txt"
POLICY_FILE_OTHERS="/home/user/policies_other.txt"
 
LOG_BASE="/home/user/logs"
 
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }
 
# =============================================================================
# Calculate previous month date ranges
# =============================================================================
 
PREV_MONTH_ANY=$(date -d "$(date +%Y-%m-01) -1 day" +%Y-%m-%d)
PREV_MONTH=$(date -d "$PREV_MONTH_ANY" +%m)
PREV_YEAR=$(date -d "$PREV_MONTH_ANY" +%Y)
PREV_MONTH_NAME=$(date -d "$PREV_MONTH_ANY" +%B)
LAST_DAY=$(date -d "${PREV_YEAR}-${PREV_MONTH}-01 +1 month -1 day" +%d)
 
START_WINDOW_BEGIN="${PREV_MONTH}/01/${PREV_YEAR}"
START_WINDOW_END="${PREV_MONTH}/07/${PREV_YEAR}"
END_WINDOW_START_DAY=$(( LAST_DAY - 6 ))
END_WINDOW_BEGIN=$(printf "%s/%02d/%s" "$PREV_MONTH" "$END_WINDOW_START_DAY" "$PREV_YEAR")
END_WINDOW_END="${PREV_MONTH}/${LAST_DAY}/${PREV_YEAR}"
 
# Create log directory
LOG_DIR="${LOG_BASE}/${PREV_MONTH_NAME}_${PREV_YEAR}"
mkdir -p "$LOG_DIR"
 
log "============================================================"
log "NetBackup Verification Run"
log "Previous month : ${PREV_MONTH_NAME} ${PREV_YEAR}"
log "Fileserver window (start-of-month): ${START_WINDOW_BEGIN} -> ${START_WINDOW_END}"
log "Others window   (end-of-month)   : ${END_WINDOW_BEGIN} -> ${END_WINDOW_END}"
log "Output directory: ${LOG_DIR}"
log "============================================================"
 
# =============================================================================
# pick_random_policy FILE
# =============================================================================
pick_random_policy() {
    local FILE="$1"
    local -a POLICIES
    while IFS= read -r LINE || [[ -n "$LINE" ]]; do
        LINE=$(echo "$LINE" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        [[ -z "$LINE" || "$LINE" == \#* ]] && continue
        POLICIES+=("$LINE")
    done < "$FILE"
 
    local COUNT=${#POLICIES[@]}
    if [[ $COUNT -eq 0 ]]; then
        echo ""
        return 1
    fi
 
    local IDX=$(( RANDOM % COUNT ))
    echo "${POLICIES[$IDX]}"
}
 
# =============================================================================
# verify_policy POLICY START_DATE END_DATE
# =============================================================================
verify_policy() {
    local POLICY="$1"
    local SEARCH_START="$2"
    local SEARCH_END="$3"
 
    # OUTFILE is set later once the backup date is known from the IMAGE line.
    # For early-exit SKIP cases we fall back to the run date.
    local RUN_DATE
    RUN_DATE=$(date +%m%d%Y)
    local OUTFILE  # declared here, assigned below
 
    log "--- Policy: ${POLICY} | Window: ${SEARCH_START} -> ${SEARCH_END} ---"
 
    # Run bpimagelist -l once, reuse for all parsing
    local RAW_OUTPUT
    RAW_OUTPUT=$(
        "$BPIMAGELIST" \
            -policy "$POLICY" \
            -d "$SEARCH_START" \
            -e "$SEARCH_END" \
            -l 2>/dev/null
    )
 
    if [[ -z "$RAW_OUTPUT" ]]; then
        OUTFILE="${LOG_DIR}/${POLICY}_${RUN_DATE}.txt"
        log "  SKIP: No backup images found in date window. bpverify will NOT be called."
        log "  Output file: ${OUTFILE}"
        echo "SKIP: No backup images found for policy '${POLICY}' in window ${SEARCH_START} -> ${SEARCH_END}" > "$OUTFILE"
        return 1
    fi
 
    # Extract from last IMAGE line:
    #   $14 = backup Unix epoch -> exact verify date
    #   $28 = number of copies  -> used as -cn
    local BACKUP_EPOCH COPY_NUM
    read -r BACKUP_EPOCH COPY_NUM < <(
        echo "$RAW_OUTPUT" \
        | awk '/^IMAGE/ {epoch=$14; copies=$28} END {print epoch, copies}'
    )
 
    if [[ -z "$BACKUP_EPOCH" || "$BACKUP_EPOCH" == "0" ]]; then
        OUTFILE="${LOG_DIR}/${POLICY}_${RUN_DATE}.txt"
        log "  SKIP: Could not extract backup timestamp from IMAGE line."
        log "  Output file: ${OUTFILE}"
        echo "SKIP: Could not extract backup timestamp for policy '${POLICY}'" > "$OUTFILE"
        return 1
    fi
 
    if [[ -z "$COPY_NUM" || "$COPY_NUM" == "0" ]]; then
        OUTFILE="${LOG_DIR}/${POLICY}_${RUN_DATE}.txt"
        log "  SKIP: Could not extract copy number from IMAGE line."
        log "  Output file: ${OUTFILE}"
        echo "SKIP: Could not extract copy number for policy '${POLICY}'" > "$OUTFILE"
        return 1
    fi
 
    local BACKUP_DATE
    BACKUP_DATE=$(date -d "@${BACKUP_EPOCH}" +%m/%d/%Y)
    local VERIFY_END
    VERIFY_END=$(date -d "@$(( BACKUP_EPOCH + 86400 ))" +%m/%d/%Y)
 
    # Name the output file after the backup date (MMDDYYYY), not the run date
    local BACKUP_DATE_FLAT
    BACKUP_DATE_FLAT=$(date -d "@${BACKUP_EPOCH}" +%m%d%Y)
    OUTFILE="${LOG_DIR}/${POLICY}_${BACKUP_DATE_FLAT}.txt"
 
    log "  Backup date: ${BACKUP_DATE} | Copy number: ${COPY_NUM}"
    log "  Output file: ${OUTFILE}"
    log "  Running: bpverify -policy ${POLICY} -s ${BACKUP_DATE} -e ${VERIFY_END} -cn ${COPY_NUM}"
 
    # Write header to output file
    {
        echo "NetBackup Verification Report"
        echo "============================================================"
        echo "Policy      : ${POLICY}"
        echo "Backup date : ${BACKUP_DATE}"
        echo "Copy number : ${COPY_NUM}"
        echo "Run date    : $(date '+%m/%d/%Y %H:%M:%S')"
        echo "============================================================"
        echo ""
    } > "$OUTFILE"
 
    # Run bpverify, tee output to both console and file
    if "$BPVERIFY" \
            -policy "$POLICY" \
            -s "$BACKUP_DATE" \
            -e "$VERIFY_END" \
            -cn "$COPY_NUM" 2>&1 | tee -a "$OUTFILE"; then
        echo "" >> "$OUTFILE"
        echo "RESULT: SUCCESS" >> "$OUTFILE"
        log "  OK: Policy '${POLICY}' copy ${COPY_NUM} verified successfully."
        log "  Report saved to: ${OUTFILE}"
        return 0
    else
        local EXIT_CODE=${PIPESTATUS[0]}
        echo "" >> "$OUTFILE"
        echo "RESULT: FAILED (exit code: ${EXIT_CODE})" >> "$OUTFILE"
        log "  ERROR: Verification FAILED for policy '${POLICY}' copy ${COPY_NUM} (exit code: ${EXIT_CODE})."
        log "  Report saved to: ${OUTFILE}"
        return 1
    fi
}
 
# =============================================================================
# run_random_verify FILE START_DATE END_DATE LABEL
# =============================================================================
run_random_verify() {
    local FILE="$1"
    local START_DATE="$2"
    local END_DATE="$3"
    local LABEL="$4"
 
    log "========== ${LABEL}: selecting random policy from ${FILE} =========="
 
    if [[ ! -f "$FILE" ]]; then
        log "ERROR: Policy file not found: ${FILE}"
        return 1
    fi
 
    local POLICY
    POLICY=$(pick_random_policy "$FILE")
 
    if [[ -z "$POLICY" ]]; then
        log "ERROR: No valid policies found in ${FILE}"
        return 1
    fi
 
    log "  Selected policy: ${POLICY}"
    verify_policy "$POLICY" "$START_DATE" "$END_DATE"
}
 
# =============================================================================
# Main — exactly 2 bpverify jobs
# =============================================================================
OVERALL_EXIT=0
 
run_random_verify "$POLICY_FILE_FILESERVERS" \
    "$START_WINDOW_BEGIN" "$START_WINDOW_END" "Fileservers" || OVERALL_EXIT=1
 
run_random_verify "$POLICY_FILE_OTHERS" \
    "$END_WINDOW_BEGIN" "$END_WINDOW_END" "Others" || OVERALL_EXIT=1
 
log "============================================================"
if [[ $OVERALL_EXIT -eq 0 ]]; then
    log "All verifications completed SUCCESSFULLY."
else
    log "One or more verifications FAILED or were skipped. Review the log above."
fi
log "============================================================"
 
exit $OVERALL_EXIT
