#!/bin/bash

# =============================================================================
# Script Name: script_template.sh
# Description: A robust, user-friendly shell script template with interactive
#              select menus and comprehensive error handling.
# Author: Joshua McKenna
# Date: 2025-01-29
# =============================================================================

# -------------------------------
# 1. Configuration and Initialization
# -------------------------------

# Move execution to the script's parent directory
INITIAL_WORKING_DIRECTORY=$(pwd)
parent_path=$(
    cd "$(dirname "${BASH_SOURCE[0]}")" || exit
    pwd -P
)
cd "$parent_path" || exit

# Check if config.env exists
if [ ! -f "$(dirname "$0")/config.env" ]; then
    print_error "config.env file is missing from the $(dirname "$0") directory."
    exit 1
else
    # shellcheck source=/dev/null
    source "$(dirname "$0")/config.env"
fi

# Check the last update date
if [[ -z "${GAM_LAST_UPDATE:-}" ]]; then
    print_info "GAM_LAST_UPDATE variable is not set in the config file."
    update_gam
else
    LAST_UPDATE_DATE=$(date -j -f "%Y-%m-%d" "${GAM_LAST_UPDATE}" "+%s")
    CURRENT_DATE_SECS=$(date -j -f "%Y-%m-%d" "${NOW}" "+%s")
    SECONDS_DIFF=$((CURRENT_DATE_SECS - LAST_UPDATE_DATE))
    DAYS_SINCE_LAST_UPDATE=$((SECONDS_DIFF / 86400))

    if [ "${DAYS_SINCE_LAST_UPDATE}" -ge "${UPDATE_INTERVAL_DAYS}" ]; then
        print_info "Checking for updates."
        update_gam
    else
        print_info "GAM was updated ${DAYS_SINCE_LAST_UPDATE} days ago. Skipping update."
    fi
fi

# Ensure the log directory exists
mkdir -p "${LOG_DIR}"

# Define global variables
NOW=$(date '+%F %H.%M.%S')
#LOG_FILE="${LOG_DIR}/$NOW.log"
date_prefix=$(date '+%Y-%m-%d %H%M')

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

cd "$INITIAL_WORKING_DIRECTORY" || exit