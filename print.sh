#!/usr/bin/env bash

# =============================================================================
# Script Name: print.sh
# Description: A user-friendly shell script with interactive
#              select menus and comprehensive error handling.
# Author: Joshua McKenna
# Date: 2025-02-04
# =============================================================================

# -------------------------------
# 1. Configuration and Initialization
# -------------------------------

# Enable strict error handling
set -euo pipefail
IFS=$'\n\t'

# Move execution to the script's parent directory
INITIAL_WORKING_DIRECTORY=$(pwd)
parent_path=$(
    cd "$(dirname "${BASH_SOURCE[0]}")"
    pwd -P
)
cd "$parent_path"

# Check if config.env exists
if [ ! -f "$(dirname "$0")/config.env" ]; then
    echo -e "'\033[1;31m'ERROR'\033[0m': config.env file is missing from the $(dirname "$0") directory."
    exit 1
else
    # shellcheck source=/dev/null
    source "$(dirname "$0")/config.env"
fi

# Define time variables
NOW=$(date '+%F %H.%M.%S')
TODAY=$(date '+%F')

# Ensure the log directory exists
mkdir -p "${LOG_DIR}/${TODAY}"/reports

# Define log variables
LOG_FILE="${LOG_DIR}/${TODAY}/$NOW $(basename "$0").log"
LOG_LEVEL="INFO"  # Set your log level here

# Set default log paths
ERR_LOG="${LOG_DIR}/${TODAY}/other/$NOW $(basename "$0") ERROR.log"
WARN_LOG="${LOG_DIR}/${TODAY}/other/$NOW $(basename "$0") WARNING.log"
INFO_LOG="${LOG_DIR}/${TODAY}/other/$NOW $(basename "$0") INFO.log"

# Determine the logging behavior based on LOG_LEVEL
if [[ "$LOG_LEVEL" == "INFO" ]]; then
    ERR_LOG="${LOG_FILE}"
    WARN_LOG="${LOG_FILE}"
    INFO_LOG="${LOG_FILE}"
elif [[ "$LOG_LEVEL" == "WARNING" ]]; then
    ERR_LOG="${LOG_FILE}"
    WARN_LOG="${LOG_FILE}"
    # INFO_LOG will remain as its default
elif [[ "$LOG_LEVEL" == "ERROR" ]]; then
    ERR_LOG="${LOG_FILE}"
    # WARN_LOG and INFO_LOG will remain as their defaults
elif [[ "$LOG_LEVEL" == "DEBUG" || "$LOG_LEVEL" == "VERBOSE" ]]; then
    exec 19> "${LOG_FILE}"
    BASH_XTRACEFD="19"
    set -x  # Enable debug mode
    # Separate logs for DEBUG/VERBOSE
else
    echo "Unsupported LOG_LEVEL: $LOG_LEVEL. Defaulting to separated ERR/WARN/INFO logs."
    # Use the defaults
fi

# Print ERROR messages in bold red.
print_error() {
    echo -e "${BOLD_RED}ERROR${RESET}: ${1:-}" | tee -a "${ERR_LOG}" >&2
}

# Print WARNING messages in bold yellow.
print_warning() {
    echo -e "${BOLD_YELLOW}WARNING${RESET}: ${1:-}" | tee -a "${WARN_LOG}"
}

# Print INFO messages in bold blue.
print_info() {
    echo -e "${BOLD_CYAN}INFO${RESET}: ${1:-}" | tee -a "${INFO_LOG}"
}

# Print SUCCESS messages in bold green.
print_success() {
    echo -e "${BOLD_GREEN}SUCCESS${RESET}: ${1:-}" | tee -a "${INFO_LOG}"
}

# Print PROMPT messages in bold purple.
# shellcheck disable=SC2120
print_prompt() {
    echo -e "${BOLD_PURPLE}ACTION REQUIRED${RESET}: ${1:-}"
}

# Print COMMAND before executing.
print_and_execute() {
    echo -e "${BOLD_WHITE}  + $*  ${RESET}" | tee -a "${INFO_LOG}"
    "$@"
}

# Function to update GAM and GAMADV-XTD3
update_gam() {
    print_info "Updating GAM and GAMADV-XTD3..."
    bash <(curl -s -S -L https://gam-shortn.appspot.com/gam-install) -l
    bash <(curl -s -S -L https://raw.githubusercontent.com/taers232c/GAMADV-XTD3/master/src/gam-install.sh) -l
    # Update the last update date in the config.env file
    local current_date
    current_date=$(date +%F)
    sed -i'' -e "s/^GAM_LAST_UPDATE=.*/GAM_LAST_UPDATE=\"$current_date\"/" "$(dirname "$0")/config.env"
    export GAM_LAST_UPDATE="$current_date"
}

date_prefix=$(date '+%Y-%m-%d')

# Check the last update date
if [[ -z "${GAM_LAST_UPDATE:-}" ]]; then
    print_info "GAM_LAST_UPDATE variable is not set in the config file."
    update_gam
else
    LAST_UPDATE_DATE=$(date -j -f "%Y-%m-%d" "${GAM_LAST_UPDATE}" "+%s")
    CURRENT_DATE_SECS=$(date -j -f "%Y-%m-%d" "${TODAY}" "+%s")
    SECONDS_DIFF=$((CURRENT_DATE_SECS - LAST_UPDATE_DATE))
    DAYS_SINCE_LAST_UPDATE=$((SECONDS_DIFF / 86400))

    if [ "${DAYS_SINCE_LAST_UPDATE}" -ge "${UPDATE_INTERVAL_DAYS}" ]; then
        print_info "Checking for updates."
        update_gam
    else
        print_info "GAM was updated ${DAYS_SINCE_LAST_UPDATE} days ago. Skipping update."
    fi
fi

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
if print_orgs_result=$(${GAM3} print orgs); then
    print_success "Reported orgs."
    "$print_orgs_result" >"$orgs_file"
else
    print_error "Failed to report orgs."
    "$print_orgs_result" >"$orgs_file"
fi
if print_users_result=$(${GAM3} print users allfields); then
    print_success "Reported users."
    "$print_users_result" >"$users_file"
else
    print_error "Failed to report orgs."
    "$print_users_result" >"$users_file"
fi
if print_groups_result=$(${GAM3} print groups allfields); then
    print_success "Reported groups."
    "$print_groups_result" >"$groups_file"
else
    print_error "Failed to report groups."
    "$print_groups_result" >"$groups_file"
fi
if print_aliases_result=$(${GAM3} print aliases); then
    print_success "Reported aliases."
    "$print_aliases_result" >"$aliases_file"
else
    print_error "Failed to report aliases."
    "$print_aliases_result" >"$aliases_file"
fi
if print_adminroles_result=$(${GAM3} print adminroles privileges); then
    print_success "Reported adminroles."
    "$print_adminroles_result" >"$roles_file"
else
    print_error "Failed to report adminroles."
    "$print_adminroles_result" >"$roles_file"
fi
if print_admins_result=$(${GAM3} print admins); then
    print_success "Reported admins."
    "$print_admins_result" >"$admins_file"
else
    print_error "Failed to report admins."
    "$print_admins_result" >"$admins_file"
fi
if print_calendars_result=$(${GAM3} all users print calendars); then
    print_success "Reported calendars."
    "$print_calendars_result" >"$calendars_file"
else
    print_error "Failed to report calendars."
    "$print_calendars_result" >"$calendars_file"
fi
if print_resources_result=$(${GAM3} print resources allfields); then
    print_success "Reported resources."
    "$print_resources_result" >"$resources_file"
else
    print_error "Failed to report resources."
    "$print_resources_result" >"$resources_file"
fi
if print_teamdriveacls_result=$(${GAM3} print teamdriveacls oneitemperrow); then
    print_success "Reported teamdriveacls."
    "$print_teamdriveacls_result" >"$teamdriveacls_file"
else
    print_error "Failed to report teamdriveacls."
    "$print_teamdriveacls_result" >"$teamdriveacls_file"
fi
if print_teamdrives_result=$(${GAM3} print teamdrives); then
    print_success "Reported teamdrives."
    "$print_teamdrives_result" >"$teamdrives_file"
else
    print_error "Failed to report teamdrives."
    "$print_teamdrives_result" >"$teamdrives_file"
fi
if print_mfa_result=$(${GAM3} print users query "isEnrolledIn2sv=False isSuspended=False"); then
    print_success "Reported mfa."
    "$print_mfa_result" >"${date_prefix} MFA.csv"
else
    print_error "Failed to report mfa."
    "$print_mfa_result" >"${date_prefix} MFA.csv"
fi

cd "$INITIAL_WORKING_DIRECTORY" || exit