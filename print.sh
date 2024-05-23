#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

source "$(dirname "$0")/config.env"

# Initialize variables
NOW=$(date '+%F')
logFile=${LOG_DIR}/$NOW.log
date_prefix=$(date '+%Y-%m-%d %H%M')

# Function to update GAM and GAMADV-XTD3
update_gam() {
    echo "Updating GAM and GAMADV-XTD3..."
    bash <(curl -s -S -L https://gam-shortn.appspot.com/gam-install) -l
    bash <(curl -s -S -L https://raw.githubusercontent.com/taers232c/GAMADV-XTD3/master/src/gam-install.sh) -l
    # Update the last update date in the config.env file
    sed -i'' -e "s/^GAM_LAST_UPDATE=.*/GAM_LAST_UPDATE=\"${NOW}\"/" "$(dirname "$0")/config.env"
    export GAM_LAST_UPDATE="${NOW}"
}

# Check the last update date
if [[ -z "${GAM_LAST_UPDATE:-}" ]]; then
    echo "GAM_LAST_UPDATE variable is not set in the config file."
    update_gam
else
    LAST_UPDATE_DATE=$(date -j -f "%Y-%m-%d" "${GAM_LAST_UPDATE}" "+%s")
    CURRENT_DATE_SECS=$(date -j -f "%Y-%m-%d" "${NOW}" "+%s")
    SECONDS_DIFF=$((CURRENT_DATE_SECS - LAST_UPDATE_DATE))
    DAYS_SINCE_LAST_UPDATE=$((SECONDS_DIFF / 86400))

    if [ "${DAYS_SINCE_LAST_UPDATE}" -ge "${UPDATE_INTERVAL_DAYS}" ]; then
        update_gam
    else
        echo "GAM was updated ${DAYS_SINCE_LAST_UPDATE} days ago. Skipping update."
    fi
fi

# Ensure the log directory exists
mkdir -p "${LOG_DIR}"

# Define the output file names with the date prefix
orgs_file="${date_prefix} gam orgs.csv"
users_file="${date_prefix} gam users.csv"
groups_file="${date_prefix} gam groups.csv"
aliases_file="${date_prefix} gam aliases.csv"
roles_file="${date_prefix} gam roles.csv"
admins_file="${date_prefix} gam admins.csv"
calendars_file="${date_prefix} gam calendars.csv"
resources_file="${date_prefix} gam resources.csv"
teamdriveacls_file="${date_prefix} gam teamdriveacls.csv"
teamdrives_file="${date_prefix} gam teamdrives.csv"

# Execute the commands and redirect the output to the respective files
${GAM3} print orgs >"$orgs_file"
${GAM3} print users allfields >"$users_file"
${GAM3} print groups allfields >"$groups_file"
${GAM3} print aliases >"$aliases_file"
${GAM3} print adminroles privileges >"$roles_file"
${GAM3} print admins >"$admins_file"
${GAM3} all users print calendars >"$calendars_file"
${GAM3} print resources allfields >"$resources_file"
${GAM3} print teamdriveacls oneitemperrow >"$teamdriveacls_file"
${GAM3} print teamdrives >"$teamdrives_file"
${GAM3} print users query "isEnrolledIn2sv=False isSuspended=False" >"${date_prefix} MFA.csv"
