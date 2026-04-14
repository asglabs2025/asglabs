#!/bin/bash
LOGFILE="/home/user/logs/crontab_logs/netbackup/daily_cron_$(date +%F).l                                                                                                                                                             og"
exec >> "$LOGFILE" 2>&1
# =============================================================================
# NetBackup Failed Job Report
# Author  : Aman Ghattaoraya
# Purpose : Queries the NetBackup job database within a configurable lookback
#           window and writes a plain-text report showing only failed jobs:
#             - Failed Jobs: completed with a non-zero exit code (action require                                                                                                                                                             d)
#           Active, completed, and unknown jobs are intentionally excluded.
#
# Job completion is determined by $11 (end epoch) being a valid non-zero
# timestamp, which is more reliable than the $2 state field in this environment.
# Status is determined by $4 — empty $4 on a completed job is treated as
# Unknown rather than Failed to avoid false alerts.
#
# Output  : /home/user/failedjobscheck/netbackup_failures_YYYY-MM-DD.txt
#
# Cron example (runs daily at 07:00):
#   0 7 * * * /home/user/netbackup_failures.sh
# =============================================================================

# =============================================================================
# Configuration - only these values should ever need changing
# =============================================================================
OUTPUT_DIR="/home/user/failedjobscheck"   # Directory to store report fi                                                                                                                                                             les
OUTPUT_FILE="$OUTPUT_DIR/netbackup_failures_$(date +%F).txt"  # Dated filename
HOURS=24                                           # Lookback window in hours
EMAIL_TO="user@domain.com"  # Report recipients
EMAIL_FROM="user@domain.com"       # Sender address (must match account configured in /etc/postfix/sasl_passwd)                                                                                                                                                              sasl_passwd account)

# =============================================================================
# Initialisation
# =============================================================================

# Create the output directory if it doesn't already exist
mkdir -p "$OUTPUT_DIR"

# =============================================================================
# Optional - Log rotation — remove report files older than 90 days
# =============================================================================
# find "$OUTPUT_DIR" -name "netbackup_failures_*.txt" -mtime +90 -delete

# Capture the current time as a Unix epoch. This is passed into awk so that
# all age comparisons use a consistent "now" timestamp throughout the run.
NOW_EPOCH=$(date +%s)

# =============================================================================
# Job query and filtering
# bpdbjobs returns one CSV line per job. Fields used:
#   $1  = Job ID
#   $2  = Job state (not reliable for routing in this environment - see $11)
#   $4  = Status code (0=Success, 1=Partial, anything else = failure)
#   $5  = Policy name
#   $6  = Schedule name
#   $7  = Client name
#   $9  = Job start time (Unix epoch)
#   $10 = Elapsed seconds counter (not a valid end epoch)
#   $11 = Job end time (Unix epoch) - reliable completion indicator:
#           > 0  = job has completed
#           = 0  = job is still active/running
#
# Output includes only failed jobs (prefixed FAILED):
#   FAILED    - $11 > 0 (done), status not 0/1 and not empty
# Active, completed, and unknown jobs are skipped.
# =============================================================================
AWK_OUTPUT=$(/usr/openv/netbackup/bin/admincmd/bpdbjobs -report -most_columns -n                                                                                                                                                             oheader | \
awk -F, -v now_epoch="$NOW_EPOCH" -v hours="$HOURS" '{

    # -----------------------------------------------------------------
    # Age filter: skip jobs outside the lookback window.
    # -----------------------------------------------------------------
    start_epoch = $9
    if (start_epoch < now_epoch - (hours * 3600)) next

    # -----------------------------------------------------------------
    # Convert start time from Unix epoch to human-readable format.
    # -----------------------------------------------------------------
    cmd = "date -d @" start_epoch " \"+%F %T\""; cmd | getline start; close(cmd)

    # -----------------------------------------------------------------
    # Determine if job is complete using $11 (end epoch).
    # $11 > 0 means the job has a valid end time = completed.
    # $11 = 0 means no end time recorded = still active.
    # -----------------------------------------------------------------
    if ($11 ~ /^[0-9]+$/ && $11+0 > 0) {
        # Job is completed - calculate elapsed and end time
        end_epoch = $11
        cmd = "date -d @" end_epoch " \"+%F %T\""; cmd | getline end; close(cmd)
        elapsed_sec = end_epoch - start_epoch
        is_done = 1
    } else {
        # Job is still active - elapsed is time since start
        end = "N/A"
        elapsed_sec = now_epoch - start_epoch
        is_done = 0
    }

    # Convert elapsed seconds into HH:MM:SS format
    hh = int(elapsed_sec / 3600)
    mm = int((elapsed_sec % 3600) / 60)
    ss = elapsed_sec % 60
    elapsed = sprintf("%02d:%02d:%02d", hh, mm, ss)

    # -----------------------------------------------------------------
    # Look up the human-readable description for the status code.
    # -----------------------------------------------------------------
    if ($4 != "") {
        err = "/usr/openv/netbackup/bin/admincmd/bperror -S " $4 " | head -1"
        err | getline msg; close(err)
    } else {
        msg = "N/A"
    }

    # -----------------------------------------------------------------
    # Only output genuinely failed jobs:
    #   Done ($11 > 0), non-zero/non-empty status -> FAILED
    # Active, completed (0/1), and unknown (empty status) jobs are skipped.
    # -----------------------------------------------------------------
    if (is_done && $4 != "" && $4 != "0" && $4 != "1") {
        # Non-zero status code - genuine failure
        printf "FAILED|JobID:%s | Client:%s | Policy:%s | Schedule:%s | Status:%                                                                                                                                                             s | %s | Start:%s | End:%s | Elapsed:%s\n",
            $1, $7, $5, $6, $4, msg, start, end, elapsed
    }
}')

# Extract failed jobs from awk output
FAILURES=$(echo "$AWK_OUTPUT" | grep "^FAILED|" | sed 's/^FAILED|//')

# =============================================================================
# Write the report file in a single block to avoid partial writes.
# =============================================================================
{
    echo "NetBackup Job Report"
    echo "Generated : $(date '+%F %T')"
    echo "Checking  : Last ${HOURS} hours"
    echo "============================================================"
    echo ""

    # Section 1: Failed jobs - action required
    if [[ -n "$FAILURES" ]]; then
        echo "  *** FAILED JOBS - ACTION REQUIRED ***"
        echo "  Please escalate to Ramesh for further investigation."
        echo ""
        echo "$FAILURES"
        echo ""
    fi

    # Section 2: All clear - only shown when no failures exist
    if [[ -z "$FAILURES" ]]; then
        echo "  *** ALL CLEAR - NO FAILED JOBS ***"
        echo ""
        echo "  No failed jobs detected in the last ${HOURS} hours."
        echo "  No action required."
    fi

    echo ""
    echo "============================================================"
    echo "End of report"
} > "$OUTPUT_FILE"

# =============================================================================
# Set permissions so the file is readable by all users/teams
# =============================================================================
chmod 777 "$OUTPUT_FILE"

# =============================================================================
# Email the report
# - Subject flags whether failures were found for easy inbox triage
# - Report file is piped as the email body
# =============================================================================
if [[ -n "$FAILURES" ]]; then
    EMAIL_SUBJECT="[ACTION REQUIRED] Warbug Pincus NetBackup Failed Jobs - $(dat                                                                                                                                                             e +%F)"
else
    EMAIL_SUBJECT="[ALL CLEAR] Warburg Pincus NetBackup Job Report - $(date +%F)                                                                                                                                                             "
fi

mailx -s "$EMAIL_SUBJECT" \
      -r "$EMAIL_FROM" \
      $EMAIL_TO < "$OUTPUT_FILE"
