#!/usr/bin/env bash

# =============================================================================
# Script Name: onboard.sh
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
    print_error "config.env file is missing from the $(dirname "$0") directory."
    exit 1
else
    # shellcheck source=/dev/null
    source "$(dirname "$0")/config.env"
fi

# Ensure the log directory exists
mkdir -p "${LOG_DIR}"

# Define global variables
NOW=$(date '+%F %H.%M.%S')
TODAY=$(date '+%F')
LOG_FILE="${LOG_DIR}/$NOW.log"
ERR_LOG="${LOG_DIR}/$NOW ERR.log"

# Print ERROR messages in bold red.
print_error() {
    echo -e "${BOLD_RED}ERROR${RESET}: ${1:-}" >&2
}

# Print WARNING messages in bold yellow.
print_warning() {
    echo -e "${BOLD_YELLOW}WARNING${RESET}: ${1:-}"
}

# Print INFO messages in bold blue.
print_info() {
    echo -e "${BOLD_CYAN}INFO${RESET}: ${1:-}"
}

# Print SUCCESS messages in bold green.
print_success() {
    echo -e "${BOLD_GREEN}SUCCESS${RESET}: ${1:-}"
}

# Print SUCCESS messages in bold green.
# shellcheck disable=SC2120
print_prompt() {
    echo -e "${BOLD_PURPLE}ACTION REQUIRED${RESET}: ${1:-}"
}

# Print COMMAND before executing.
print_and_execute() {
    echo -e "${BOLD_WHITE}+ $*${RESET}"
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

# -------------------------------
# 2. Utility Functions
# -------------------------------

validate_email() {
    # Example: use a regular expression to check for valid email format
    [[ $1 =~ ^[^@]+@[^@]+\.[^@]+$ ]] || print_error "Invalid email address: $1"
}

# Initialize the log file.
initialize_logging() {
    # Create a new log file for each run of the script.
    echo
    echo "========================================"
    print_info "Starting $0 script at $(date)"
    echo "========================================"
    echo "GAM3 command alias set to ${GAM3}"
    ${GAM3} version
    echo "Bash version ${BASH_VERSION}"
    echo "Logging to ${LOG_FILE}"
    echo
}

# Print HELP instructions.
print_help() {
    echo
    echo -e "${BOLD_WHITE}Usage:${RESET} $0 [OPTIONS]"
    echo
    echo -e "${BOLD_WHITE}Options:${RESET}"
    echo "  -h, --help    Display this help message and exit."
    echo
    echo -e "${BOLD_WHITE}Description:${RESET}"
    echo "  This script provides an interactive menu for onboarding new users in Google"
    echo "  Workspace. It uses the Google Apps Manager (GAMADV-XTD3) command-line tool"
    echo "  to interact with Google Workspace APIs."
    echo
    echo "  Without any options, it launches the interactive menu."
    echo
    echo -e "${BOLD_WHITE}Examples:${RESET}"
    echo -e "  Display help:"
    echo "    $0 -h | --h | --help | help"
    echo
    echo -e "  ${WHITE}Provide all arguments up-front:${RESET}"
    echo -e "    ${BOLD_YELLOW}1${RESET} onboard_first_name         User first name (string)"
    echo -e "    ${BOLD_YELLOW}2${RESET} onboard_last_name          User last name (string)"
    echo -e "    ${BOLD_YELLOW}3${RESET} onboard_user               User new domain email (user@company.com)"
    echo -e "    ${BOLD_YELLOW}4${RESET} manager_email_address      User manager email (manager@company.com)"
    echo -e "    ${YELLOW}5${RESET} recovery_email                  Personal email for the onboarding user (email@domain.com)"
    echo -e "    ${YELLOW}6${RESET} campus                          Assigned campus (AND, SW, CRK, MT, SYS)"
    echo -e "    ${YELLOW}7${RESET} job_title                       User official job title, for use in signature (string)"
    echo -e "    ${YELLOW}8${RESET} birthday                        User birthday (YYYY-MM-DD) for company birthdays calendar"
    echo
    echo -e "  ${WHITE}Run the interactive menu:${RESET}"
    echo "    $0"
    echo
}

# -------------------------------
# 3. Task Functions
# -------------------------------

# Exits the script.
task_exit() {
    ret=$?
    echo
    if [ $ret -ne 0 ]; then
        echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        echo -e "Exit last with code $ret"
        echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    else
        echo "========================================"
        echo "========================================"
    fi
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

confirm_continue() {
    print_prompt
    read -r -p "Press any key to continue..." -n1 -s
    echo
}

confirm_inputs() {
    echo
    print_info "Confirming inputs at $(date)"
    echo
    echo "Employee: ${onboard_first_name} ${onboard_last_name} (${onboard_user})"
    echo "Manager: ${manager_email_address}"
    echo "Recovery email: ${recovery_email}"
    echo "Campus: ${campus}"
    echo "Job title: ${job_title}"
    echo "Birthday: ${birthday}"
    echo
    confirm_continue
    echo
    print_success "Inputs confirmed."
    echo
}

get_info() {
    echo
    echo "Entering get_info function at $(date)"
    echo
    echo "Logging newly onboarded user's info for audit..."
    ${GAM3} info user "${onboard_user}"
    echo
    print_success "Employee information retrieved."
    echo
    echo "Exiting get_info function at $(date)"
    echo
}

update_info() {
    echo
    echo "Entering update_info function at $(date)"
    echo "Updating employee organization info..."
    echo
    print_prompt
    read -r -p "Please enter the type of employee (e.g., Staff, Fellows, Mobilization, Seconded, etc.):   " type_of_employee
    echo
    print_info "Employee type set to: ${type_of_employee}"
    echo
    print_prompt
    read -r -p "Enter all associated departments, separated by commas (e.g. Youth,College,Children):   " input
    echo
    IFS=',' read -r -a departments <<<"$input"
    if [[ -z "${campus}" ]]; then
        print_prompt "The 'campus' variable is not set. Please enter it now."
        read -p "Please enter the employee's campus: " -r campus
        echo "Campus set to: ${campus}"
    else
        echo "Campus already set to: ${campus}"
    fi
    echo
    print_info "${onboard_user} is designated as ${type_of_employee} at ${campus}, assigned to these departments: ${departments[*]}"
    echo
    confirm_continue
    echo
    ${GAM3} update user "${onboard_user}" relation manager "${manager_email_address}" organization description "${type_of_employee}" costcenter "${campus}" department "${departments[*]}" title "${job_title}" primary
    echo
    print_success "Employee information updated."
    echo
    echo "Exiting update_info function at $(date)"
    echo
}

create_user() {
    echo
    echo "Entering create_user function at $(date)"
    echo "Creating new user with email ${onboard_user}..."
    ${GAM3} create user "${onboard_user}" firstname "${onboard_first_name}" lastname "${onboard_last_name}" org New\ users notify "${recovery_email},${CC_HR}" subject "[ACTION REQUIRED] Activate your #email# email" password "${TEMP_PASS}" notifypassword "${TEMP_PASS}" changepasswordatnextlogin
    echo "...setting employment start date..."
    ${GAM3} update user "${onboard_user}" Employment_History.Start_dates multivalued "$(date '+%F')" #https://github.com/GAM-team/GAM/wiki/GAM3DirectoryCommands#setting-custom-user-schema-fields-at-create-or-update
    echo
    print_success "Emailed credentials to ${recovery_email} and ${CC_HR}"
    echo
    print_success "New user account for ${onboard_user} created."
    echo
    echo "Exiting create_user function at $(date)"
    echo
}

add_birthday() {
    echo
    echo "Entering add_birthday function at $(date)"
    echo
    if [ -z "${birthday:-}" ]; then
        read -r -p "Enter the user's birthday (YYYY-MM-DD): " birthday
        echo
    fi
    echo "Adding ${onboard_user}'s birthday to the staff birthday calendar..."
    ${GAM3} calendar "${onboard_user}" addevent attendee "${BDAY_CAL}" start allday "${birthday}" end allday "${birthday}" summary "${onboard_first_name} ${onboard_last_name}'s birthday!" recurrence "RRULE:FREQ=YEARLY" transparency transparent
    echo
    print_success "Birthday added to the calendar."
    echo
    echo "Exiting add_birthday function at $(date)"
    echo
}

view_signature() {
    echo
    echo "Entering view_signature function at $(date)"
    echo "Fetching the current user email signature..."
    print_info "Here's the ${onboard_user}'s current email signature:"
    ${GAM3} user "${onboard_user}" show signature format
    print_success "Current email signature retrieved."
    echo "Exiting view_signature function at $(date)"
    echo
}

set_signature() {
    echo
    echo "Entering set_signature function at $(date)"
    if [ -z "${job_title:-}" ]; then
        read -p "Enter the onboard user's job title: " -r job_title
    fi
    echo "Setting up email signature..."
    # shellcheck disable=SC2153
    ${GAM3} user "${onboard_user}" signature file "${SIG_FILE}" replace NAME "${onboard_first_name} ${onboard_last_name}" replace TITLE "${job_title}"
    echo
    print_success "Signature set."
    echo
    read -p "Do you want to view the signature to confirm it was set properly? (y/n): " -r response
    echo
    case "$response" in
    [Yy]*)
        print_and_execute view_signature
        ;;
    [Nn]*)
        print_info "Signature review skipped."
        ;;
    *)
        print_warning "Invalid response. Signature review skipped."
        ;;
    esac
    echo
    echo "Exiting set_signature function at $(date)"
    echo
}

add_groups() {
    echo
    echo "Entering add_groups function at $(date)"
    echo
    print_prompt "Time to add the user to groups!"
    echo
    read -r -p "Please enter all groups separated by commas (e.g. group1@domain.com,group2@domain.com): " groups_input
    echo
    echo "Groups input: ${groups_input}"
    groups_input=$(echo "$groups_input" | tr '[:upper:]' '[:lower:]')
    IFS=',' read -r -a groups <<<"$groups_input"
    for group in "${groups[@]}"; do
        echo
        read -r -p "Enter the permission level for $group (e.g., member|manager|owner): " permission
        permission=$(echo "$permission" | tr '[:upper:]' '[:lower:]')
        echo
        echo "Adding ${onboard_user} to ${group} as ${permission}"
        echo
        case "$permission" in
        member | manager | owner)
            if ${GAM3} update group "${group}" add "${permission}" user "${onboard_user}"; then
                print_success "Successfully added ${onboard_user} to ${group} as a ${permission}."
                echo
            else
                print_error "Failed to add ${onboard_user} to ${group}" >&2
                echo
            fi
            ;;
        *)
            print_warning "Invalid permission level: ${permission}. Valid options are member | manager | owner." >&2
            echo
            ;;
        esac
    done
    echo
    print_success "User added to groups."
    echo
    echo "Exiting add_groups function at $(date)"
    echo
}

add_calendars() {
    echo
    echo "Entering add_calendars function at $(date)"
    echo
    print_prompt "Time to add user to calendars!"
    echo
    read -r -p "Please enter all calendar addresses separated by commas (e.g. calendar1@domain.com,calendar2@domain.com): " calendars_input
    echo
    echo "Calendars input: ${calendars_input}"
    echo
    #https://github.com/GAM-team/GAM/wiki/CalendarExamples
    calendars_input=$(echo "$calendars_input" | tr '[:upper:]' '[:lower:]')
    IFS=',' read -r -a calendars <<<"$calendars_input"
    for calendar in "${calendars[@]}"; do
        echo
        read -r -p "Enter the permission level for $calendar (e.g. freebusy|read|editor|owner): " permission
        permission=$(echo "$permission" | tr '[:upper:]' '[:lower:]')
        echo
        echo "Adding ${onboard_user} to ${calendar} as ${permission}"
        echo
        case "$permission" in
        freebusy | read | editor | owner)
            if ${GAM3} calendar "${calendar}" add "${permission}" "${onboard_user}" sendnotifications false; then
                print_success "Successfully added ${onboard_user} to ${calendar} as a ${permission}."
                echo
                ${GAM3} user "${onboard_user}" add calendars "${calendar}" color graphite hidden false selected false notification clear || print_error "Failed to add ${calendar} to ${onboard_user}'s sidebar" >&2
                echo
            else
                print_error "Failed to add ${onboard_user} to ${calendar}" >&2
                echo
            fi
            ;;
        *)
            print_warning "Invalid permission level: ${permission}. Valid options are freebusy | read | editor | owner." >&2
            echo
            ;;
        esac
    done

    echo
    print_success "User added to calendars."
    echo
    echo "Exiting add_calendars function at $(date)"
    echo
}

update_marriage() {
    echo
    echo "Entering update_marriage function at $(date)"
    echo
    print_prompt "Updating employee name and primary email..."
    echo
    read -r -p "First name: " new_fname
    read -r -p "Last name: " new_lname
    read -r -p "New email: " new_email
    echo
    ${GAM3} update user "${onboard_user}" firstname "${new_fname}" lastname "${new_lname}" primaryemail "${new_email}" || print_error "Failed to change ${onboard_user}'s name" >&2
    echo
    echo "Exiting update_marriage function at $(date)"
    echo
}

end_logger() {
    echo
    print_success "Google Workspace boarding process complete"
    echo
    echo "========================================"
    echo "========================================"
}

trap 'print_warning "Interrupted by user."; exit 0' INT
trap 'print_error "Error on line ${LINENO}"; exit 1' ERR
# trap 'print_info "Exiting ${0}"; exit' EXIT

exec 1> >(tee -a "${LOG_FILE}")
exec 2> >(tee -a "${ERR_LOG}" "${LOG_FILE}")

# -------------------------------
# 4. Menu Setup
# -------------------------------

# Define menu options
choices=(
    "Create a new user account"
    "Add user's birthday to the staff calendar"
    "Print info for an existing user account"
    "Update details: manager, campus, department, title"
    "Print an existing user email signature"
    "Configure a standard format email signature"
    "Add user to new groups"
    "Add user to new calendars"
    "Update identity: name, primary email"
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
            echo
            print_and_execute create_user
            ;;
        "${choices[1]}")
            echo
            print_and_execute add_birthday
            ;;
        "${choices[2]}")
            echo
            print_and_execute get_info
            ;;
        "${choices[3]}")
            echo
            print_and_execute update_info
            ;;
        "${choices[4]}")
            echo
            print_and_execute view_signature
            ;;
        "${choices[5]}")
            echo
            print_and_execute set_signature
            ;;
        "${choices[6]}")
            echo
            print_and_execute add_groups
            ;;
        "${choices[7]}")
            echo
            print_and_execute add_calendars
            ;;
        "${choices[8]}")
            echo
            print_and_execute update_marriage
            ;;
        *)
            echo
            print_warning "Invalid selection, please try again."
            ;;
        esac
    done
}

# -------------------------------
# 6. Script Entry Point
# -------------------------------

handle_help "$@"

initialize_logging
confirm_inputs

# Display the menu and handle user selection
while true; do
    echo
    main_menu
    echo
    echo "----------------------------------------"
    echo
    read -r -p "Would you like to perform another operation? (y/n): " yn
    case "$yn" in
    [Yy]*)
        ;;
    [Nn]*)
        task_exit
        ;;
    *)
        print_warning "Please answer yes or no."
        ;;
    esac
    echo | tee -a "$LOG_FILE"
done

end_logger | tee -a "$LOG_FILE"

cd "$INITIAL_WORKING_DIRECTORY"