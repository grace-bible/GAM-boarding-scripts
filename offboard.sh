#!/usr/bin/env bash

# =============================================================================
# Script Name: offboard.sh
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
    echo -e "    ${BOLD_YELLOW}1${RESET} offboard_user      User email for the offboarding user"
    echo -e "    ${BOLD_YELLOW}2${RESET} receiving_user     User email for the receiving user of any transfers"
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
    echo "Employee to offboard: ${offboard_user}"
    echo "Employee to receive transfers: ${receiving_user}"
    echo
    confirm_continue
    echo
    print_success "Inputs confirmed."
    echo
}





get_info() {
    echo
    print_info "Entering get_info function at $(date)"
    echo
    echo "Fetching ${offboard_user}'s info for audit..."
    if user_info=$(${GAM3} info user "$offboard_user"); then
        print_success "$user_info"
    else
        print_warning "$user_info"
    fi
    echo
    echo "Showing email forwards for ${offboard_user}..."
    if user_forwards=$(${GAM3} user "$offboard_user" show forwards); then
        print_success "$user_forwards"
    else
        print_warning "$user_forwards"
    fi
    echo
    echo "Showing Shared Drives for ${offboard_user}..."
    if user_teamdrives=$(${GAM3} user "$offboard_user" show teamdrives); then
       print_success "$user_teamdrives"
    else
        print_warning "$user_teamdrives"
    fi
    echo
    echo "Showing calendars for ${offboard_user}..."
    if user_calendars=$(${GAM3} user "$offboard_user" show calendars); then
        print_success "$user_calendars"
    else
        print_warning "$user_calendars"
    fi
    echo
    echo "${offboard_user}'s pre-offboarding info logged."
    echo
    echo "Exiting get_info function at $(date)"
    echo
}

unsuspend() {
    echo
    print_info "Entering unsuspend function at $(date)"
    echo
    echo "Unsuspending user account for offboarding..."
    if user_unsuspend_result=$(${GAM3} update user "$offboard_user" suspended off); then
        print_success "$user_unsuspend_result"
    else
        print_error "$user_unsuspend_result"
        task_exit
    fi
    echo
    echo "Waiting for suspension to be removed..."
    sleep 10
    echo "Exiting unsuspend function at $(date)"
    echo
}

set_org_unit() {
    echo
    print_info "Entering set_org_unit function at $(date)"
    echo
    echo "Moving ${offboard_user} to offboarding OU..."
    if user_ou_result=$(${GAM3} update org 'Inactive' move user "${offboard_user}"); then
        print_success "$user_ou_result"
    else
        print_error "$user_ou_result"
    fi
    echo
    echo "Exiting set_org_unit function at $(date)"
    echo
}

reset_password() {
    echo
    print_info "Entering reset_password function at $(date)"
    echo
    echo "Generating random password..."
    if user_pass_reset=$(${GAM3} update user "$offboard_user" password random); then
        print_success "$user_pass_reset"
    else
        print_error "$user_pass_reset"
    fi
    echo
    echo "Requiring password change on next login..."
    ${GAM3} update user "$offboard_user" changepassword on
    sleep 2
    ${GAM3} update user "$offboard_user" changepassword off
    echo
    print_success "${offboard_user}'s password changed."
    echo
    echo "Exiting reset_password function at $(date)"
    echo
}

reset_recovery() {
    echo
    print_info "Entering reset_recovery function at $(date)"
    echo
    echo "Erasing recovery options for ${offboard_user}..."
    if user_recovery_reset=$(${GAM3} update user "$offboard_user" recoveryemail "" recoveryphone ""); then
        print_success "$user_recovery_reset"
    else
        print_error "$user_recovery_reset"
    fi
    echo
    echo "Exiting reset_recovery function at $(date)"
    echo
}

set_endDate() {
    echo
    print_info "Entering set_endDate function at $(date)"
    echo
    echo "Setting ${offboard_user} end date to today..."
    if user_end_date=$(${GAM3} update user "$offboard_user" Employment_History.End_dates multivalued "$NOW"); then
        print_success "$user_end_date"
    else
        print_error "$user_end_date"
    fi
    echo
    echo "Exiting set_endDate function at $(date)"
    echo
    #https://github.com/GAM-team/GAM/wiki/GAM3DirectoryCommands#setting-custom-user-schema-fields-at-create-or-update
}

deprovision() {
    echo
    set_org_unit
    echo
    print_info "Entering deprovision function at $(date)"
    echo
    echo "Deprovisioning application passwords, backup verification codes, and access tokens..."
    echo "Disabling POP/IMAP access, signing out all devices, and turning off MFA..."
    if user_deprovision=$(${GAM3} user "$offboard_user" deprovision popimap signout); then #turnoff2sv
        print_success "$user_deprovision"
    else
        print_error "$user_deprovision"
    fi
    echo
    echo "Generating new MFA backup codes..."
    if user_mfa_reset=$(${GAM3} user "$offboard_user" update backupcodes); then
        print_success "$user_mfa_reset"
    else
        print_error "$user_mfa_reset"
    fi
    echo
    echo "Exiting deprovision function at $(date)"
    echo
    #https://github.com/taers232c/GAMADV-XTD3/wiki/Users-Deprovision
}

remove_directory() {
    echo
    print_info "Entering remove_directory function at $(date)"
    echo
    echo "Hiding ${offboard_user} from the Global Address List (GAL)..."
    if user_unlist_directory=$(${GAM3} update user "$offboard_user" gal off); then
        print_success "$user_unlist_directory"
    else
        print_warning "$user_unlist_directory"
    fi
    echo
    echo "Exiting remove_directory function at $(date)"
    echo
    #https://github.com/GAM-team/GAM/wiki/GAM3DirectoryCommands
}

forward_emails() {
    echo
    print_info "Entering forward_emails function at $(date)"
    echo
    echo "Forwarding emails..."
    if user_unforward=$(${GAM3} user "$offboard_user" print forwardingaddresses | ${GAM3} csv - gam user "~User" delete forwardingaddress "~forwardingEmail"); then
        print_success "$user_unforward"
        echo "User-configured forwarding for ${offboard_user} has been deleted."
    else
        print_warning "$user_unforward"
    fi
    echo
    echo "...granting delegate access to $receiving_user..."
    if user_forward_recipient=$(${GAM3} user "$offboard_user" add forwardingaddress "$receiving_user"); then
        print_success "$user_forward_recipient"
        echo "Email for ${offboard_user} has been forwarded to ${receiving_user}..."
    else
        print_error "$user_forward_recipient"
    fi
    echo
    if archive_after_forward=$(${GAM3} user "$offboard_user" forward on "$receiving_user" archive); then
        print_success "$archive_after_forward"
        echo "Set ${offboard_user} inbox to archive after forwarding."
    else
        print_warning "$archive_after_forward"
    fi
    echo
    if user_delegate_result=$(${GAM3} user "$offboard_user" delegate to "$receiving_user"); then
        print_success "$user_delegate_result"
        echo "Email for ${offboard_user} has been delegated to ${receiving_user}."
    else
        print_error "$user_delegate_result"
    fi
    echo
    echo "Deleting ${offboard_user}'s email aliases..."
    if user_aliases_result=$(${GAM3} user "$offboard_user" delete aliases); then
        print_success "$user_aliases_result"
        echo "${offboard_user}'s email aliases were deleted."
    else
        print_error "$user_aliases_result"
    fi
    echo
    echo "Exiting forward_emails function at $(date)"
    echo
    #https://github.com/taers232c/GAMADV-XTD3/wiki/Users-Gmail-Forwarding
}

set_autoreply() {
    echo
    print_info "Entering set_autoreply function at $(date)"
    echo
    company="Grace Bible Church"
    subject="No longer at $company"
    message="Thank you for contacting me. I am no longer working at $company. Please direct any future correspondence to $receiving_user."
    startDate=$(date +%F)
    endDate=$(date -v +1y +%F)
    print_info "Autoreply message will read:"
    echo "Subject: ${subject}"
    echo "Message: ${message}"
    echo "Autoreply until: ${endDate}"
    echo
    print_prompt
    confirm_continue
    echo
    echo "Configuring email autoreply..."
    if user_autoreply=$(${GAM3} user "$offboard_user" vacation on subject "$subject" message "$message" startdate "$startDate" enddate "$endDate"); then
        print_success "$user_autoreply"
        echo "Email autoreply for ${offboard_user} set."
    else
        print_warning "$user_autoreply"
    fi
    echo
    echo "Exiting set_autoreply function at $(date)"
    echo
}

transfer_drive() {
    echo
    print_info "Entering transfer_drive function at $(date)"
    echo
    echo "Transferring Drive..."
    # Runs the drive transfer locally instead of using the bulk transfer feature
    if user_transfer_drive=$(${GAM3} create datatransfer "$offboard_user" gdrive "$receiving_user"); then
        print_success "$user_transfer_drive"
        echo "${offboard_user}'s My Drive was transferred to ${receiving_user}"
    else
        print_error "$user_transfer_drive"
    fi
    echo
    echo "Exiting transfer_drive function at $(date)"
    echo
    # ${GAM3} user "$offboard_user" transfer drive "$receiving_user"
    #https://github.com/taers232c/GAMADV-XTD3/wiki/Users-Drive-Transfer
}

transfer_calendar() {
    echo
    print_info "Entering transfer_calendar function at $(date)"
    echo
    echo "Transferring Calendar..."
    if user_transfer_cal=$(${GAM3} add datatransfer "$offboard_user" calendar "$receiving_user" releaseresources); then
        print_success "$user_transfer_cal"
        echo "${offboard_user}'s calendar was transferred to ${receiving_user}"
    else
        print_error "$user_transfer_cal"
    fi
    echo
    echo "Exiting transfer_calendar function at $(date)"
    echo
    # ${GAM3} calendar "$offboard_user" add owner "$receiving_user"
}

remove_groups() {
    echo
    print_info "Entering remove_groups function at $(date)"
    echo
    echo "Removing from groups..."
    if user_delete_groups=$(${GAM3} user "$offboard_user" delete groups); then
        print_success "$user_delete_groups"
        echo "${offboard_user} removed from groups."
    else
        print_error "$user_delete_groups"
    fi
    echo
    echo "Exiting remove_groups function at $(date)"
    echo
}

remove_drives() {
    echo
    print_info "Entering remove_drives function at $(date)"
    echo
    echo "Removing from Shared Drives..."
    ${GAM3} redirect csv ./SharedDriveAccess.csv multiprocess user "$offboard_user" print shareddrives fields id,name
    ${GAM3} redirect stdout ./DeleteSharedDriveAccess.txt multiprocess redirect stderr stdout csv ./SharedDriveAccess.csv gam delete drivefileacl ~~id~~ ~~User~~
    echo
    print_success "${offboard_user} removed from Shared Drives."
    echo
    echo "Cleaning up temporary files..."
    rm ./SharedDriveAccess.csv
    rm ./DeleteSharedDriveAccess.txt
    echo
    print_success "Temporary files deleted."
    echo
    echo "Exiting remove_drives function at $(date)"
    echo
}

suspend() {
    echo
    print_info "Waiting for last changes to take effect..."
    sleep 10
    if user_suspend_result=$(${GAM3} update user "$offboard_user" suspended on); then
        print_success "$user_suspend_result"
    else
        print_error "$user_suspend_result"
    fi
    echo
    echo "${offboard_user} was suspended."
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
    "Get user pre-offboarding info for audit"
    "Set employee end date"
    "Erase password and pass recovery options"
    "Clear app passwords, backup codes, and access tokens"
    "Move to Inactive OU and erase from directory (GAL)"
    "Forward, delegate, configure autoreply for email"
    "Transfer Google Drive files"
    "Transfer Google Calendars and events"
    "Remove from all Google Groups"
    "Fully remove from all Shared Drive files"
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
            print_and_execute get_info
            echo
            break
            ;;
        "${choices[1]}")
            echo
            print_and_execute set_endDate
            echo
            break
            ;;
        "${choices[2]}")
            echo
            print_and_execute reset_password
            echo
            print_and_execute reset_recovery
            echo
            break
            ;;
        "${choices[3]}")
            echo
            print_and_execute deprovision
            echo
            break
            ;;
        "${choices[4]}")
            echo
            print_and_execute set_org_unit
            echo
            print_and_execute remove_directory
            echo
            break
            ;;
        "${choices[5]}")
            echo
            print_and_execute forward_emails
            echo
            print_and_execute set_autoreply
            echo
            break
            ;;
        "${choices[6]}")
            echo
            print_and_execute transfer_drive
            echo
            break
            ;;
        "${choices[7]}")
            echo
            print_and_execute transfer_calendar
            echo
            break
            ;;
        "${choices[8]}")
            echo
            print_and_execute remove_groups
            echo
            break
            ;;
        "${choices[9]}")
            echo
            print_and_execute remove_drives
            echo
            break
            ;;
        *)
            echo
            print_warning "Invalid selection, please try again."
            echo
            break
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
        break
        ;;
    *)
        print_warning "Please answer Y or N."
        ;;
    esac
    echo
done

end_logger

cd "$INITIAL_WORKING_DIRECTORY"

#Heavily inspired by Sean Young's [deprovision.sh](https://github.com/seanism/IT/tree/5795238dc1309f245d939c89e975c805dda745f3/GAM)