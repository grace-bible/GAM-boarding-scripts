#!/bin/bash

# =============================================================================
# Script Name: script_template.sh
# Description: A robust, user-friendly shell script template with interactive
#              select menus and comprehensive error handling.
# Author: Joshua McKenna
# Date: 2025-01-24
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
LOG_FILE="${LOG_DIR}/$NOW.log"

# -------------------------------
# 2. Utility Functions
# -------------------------------

# Print HELP instructions.
print_help() {
    echo -e "${BOLD_WHITE}Usage:${RESET} $0 [OPTIONS]"
    echo
    echo -e "${BOLD_WHITE}Options:${RESET}"
    echo "  -h, --help    Display this help message and exit."
    echo
    echo -e "${BOLD_WHITE}Description:${RESET}"
    echo "  This script provides an interactive menu for onboarding new users in Google"
    echo
    echo -e "${BOLD_WHITE}Examples:${RESET}"
    echo -e "  Display help:"
    echo "    $0 -h | --h | --help | help"
    echo
    echo -e "  ${WHITE}Provide all arguments up-front:${RESET}"
    echo -e "    ${BOLD_YELLOW}1${RESET} option"
    echo
    echo -e "  ${WHITE}Run the interactive menu:${RESET}"
    echo "    $0"
}

# Initialize the log file.
initialize_logging() {
    # Create a new log file for each run of the script.
    echo "========================================"
    echo "Starting $0 script at $(date)"
    echo "========================================"
    echo "GAM3 command alias set to ${GAM3}"
    ${GAM3} version
    echo "Logging to ${LOG_FILE}"
    echo
}

# -------------------------------
# 3. Task Functions
# -------------------------------

# Exits the script.
task_exit() {
    echo -e "Exit last with code $?"
    return 0
}

handle_help() {
    if [ "$#" -eq 0 ]; then
        print_help
        exit 0
    fi

    case "$1" in
    -h | --h | --help | help)
        print_help
        exit 0
        ;;
    *)
        return 0
        ;;
    esac
}

#Check for arguments
if [[ $# -ge 3 ]]; then
    echo
    first_arg="$1"
    second_arg="$2"
    third_arg="${3:-}"
    echo
else
    echo
    print_warning "Warn the user here."
    echo
fi

confirm_continue() {
    print_prompt
    read -r -n1 -s -p "Press any key to continue..."
}

confirm_inputs() {
    echo
    print_info "Confirming inputs at $(date)"
    echo "First: ${first_arg}"
    echo "Second: ${second_arg}"
    echo "Third: ${third_arg}"
    echo
    confirm_continue
    echo
    print_success "Inputs confirmed."
    echo
}

first_action() {
    return
}

end_logger() {
    echo
    print_success "Google Workspace boarding process complete"
    echo
    echo "========================================"
    echo "========================================"
}

# -------------------------------
# 4. Menu Setup
# -------------------------------

# Define menu options
choices=(
    "First action"
    "Second action"
    "Cancel"
)

# Set the prompt
PS3="Please select one of the options: "

# -------------------------------
# 5. Main Menu Function
# -------------------------------

main_menu() {
    select choice in "${choices[@]}"; do
        case "$choice" in
        "${choices[0]}")
            print_and_execute confirm_inputs
            break
            ;;
        "${choices[1]}")
            print_and_execute first_action
            break
            ;;
        *)
            print_warning "Invalid selection, please try again."
            break
            ;;
        esac
    done
}

# -------------------------------
# 6. Script Entry Point
# -------------------------------

handle_help "$@"

initialize_logging | tee -a "$LOG_FILE"
confirm_inputs | tee -a "$LOG_FILE"

# Display the menu and handle user selection
while true; do
    echo | tee -a "$LOG_FILE"
    main_menu
    echo | tee -a "$LOG_FILE"
    echo "----------------------------------------" | tee -a "$LOG_FILE"
    echo | tee -a "$LOG_FILE"
    read -r -p "Would you like to perform another operation? (y/n): " yn
    case "$yn" in
    [Yy]*)
        ;;
    [Nn]*)
        task_exit
        break
        ;;
    *)
        print_warning "Please answer yes or no."
        ;;
    esac
    echo | tee -a "$LOG_FILE"
done

end_logger | tee -a "$LOG_FILE"

cd "$INITIAL_WORKING_DIRECTORY"
