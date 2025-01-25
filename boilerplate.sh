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

# Define color codes for output
WHITE='\033[0;37m'
BOLD_WHITE='\033[1;37m'
# shellcheck disable=SC2034
CYAN='\033[0;36m'
BOLD_CYAN='\033[1;36m'
# shellcheck disable=SC2034
GREEN='\033[0;32m'
BOLD_GREEN='\033[1;32m'
# shellcheck disable=SC2034
PURPLE='\033[0;35m'
# shellcheck disable=SC2034
BOLD_PURPLE='\033[1;35m'
# shellcheck disable=SC2034
RED='\033[0;31m'
BOLD_RED='\033[1;31m'
# shellcheck disable=SC2034
YELLOW='\033[0;33m'
BOLD_YELLOW='\033[1;33m'
RESET='\033[0m' # No Color

# Move execution to the script's parent directory
INITIAL_WORKING_DIRECTORY=$(pwd)
parent_path=$(
    cd "$(dirname "${BASH_SOURCE[0]}")"
    pwd -P
)
cd "$parent_path"

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

# Print ERROR messages in bold red.
print_error() {
    echo -e "${BOLD_RED}ERROR${RESET}: $1" >&2
}

# Print WARNING messages in bold yellow.
print_warning() {
    echo -e "${BOLD_YELLOW}WARNING${RESET}: $1"
}

# Print INFO messages in bold blue.
print_info() {
    echo -e "${BOLD_BLUE}INFO${RESET}: $1"
}

# Print SUCCESS messages in bold green.
print_success() {
    echo -e "${BOLD_GREEN}SUCCESS${RESET}: $1"
}

# Print SUCCESS messages in bold green.
print_prompt() {
    echo -e "${BOLD_CYAN}ACTION REQUIRED${RESET}: $1"
}

# Print command before executing.
print_and_execute() {
    echo -e "${BOLD_WHITE}+ $*${RESET}" | tee -a "$LOG_FILE"
    "$@" | tee -a "$LOG_FILE"
}

# Check if config.env exists
if [ ! -f "$(dirname "$0")/config.env" ]; then
    print_error "config.env file is missing from the $(dirname "$0") directory."
    exit 1
else
    # shellcheck source=/dev/null
    source "$(dirname "$0")/config.env"
fi

# Ensure the log directory exists
mkdir -p "${LOG_DIR}"

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
    print_info "Exiting program."
    exit 0
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
    first_arg="$1"
    second_arg="$2"
    third_arg="${3:-}"
    echo
else
    print_warning "Warn the user here."
    echo
fi

confirm_continue() {
    echo
    print_prompt "Press any key to continue..."
    echo
    read -r -n1 -s
    echo
    echo "Continuing execution at $(date)"
    echo
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
    sleep 2
}

first_action() {
    return
}

end_logger() {
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
confirm_continue

# Display the menu and handle user selection
while true; do
    echo
    echo
    main_menu
    echo | tee -a "$LOG_FILE"
    echo | tee -a "$LOG_FILE"
    read -r -p "Would you like to perform another operation? (y/n): " yn
    case "$yn" in
    [Yy]*) ;;
    [Nn]*) task_exit ;;
    *) print_warning "Please answer yes or no." ;;
    esac
done

end_logger | tee -a "$LOG_FILE"

cd "$INITIAL_WORKING_DIRECTORY"
