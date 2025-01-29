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
}

# Initialize the log file.
initialize_logging() {
    # Create a new log file for each run of the script.
    echo "========================================"
    print_info "Starting $0 script at $(date)"
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
if [[ $# -ge 1 ]]; then
    echo
    offboard_user="$1"
    receiving_user="${2:-}"
    echo
else
    echo
    echo "You ran the script without adequate arguments..."
    # Get user input for missing arguments
    echo
    read -r -p "Input the email address of the USER TO OFFBOARD from Google Workspace, followed by [ENTER]   " offboard_user
    offboard_user=$(echo "$offboard_user" | tr '[:upper:]' '[:lower:]')
    echo
    read -r -p "Input the email address of the USER TO RECEIVE from ${offboard_user}, followed by [ENTER]   " receiving_user
    receiving_user=$(echo "$receiving_user" | tr '[:upper:]' '[:lower:]')
    echo
fi

confirm_continue() {
    print_prompt
    read -r -n1 -s -p "Press any key to continue..."
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

# -------------------------------
# 4. Menu Setup
# -------------------------------

# Define menu options
choices=(
    "Get user pre-offboarding info for audit"
    "Generate a random password"
    "Erase password recovery options"
    "Move user to Inactive OU"
    "Set employee end date in directory"
    "Clear app passwords, backup codes, and access tokens"
    "Remove user from Global Address List (GAL)"
    "Forward emails, grant delegate access recipient"
    "Configure email autoreply"
    "Transfer Google Drive files"
    "Transfer Google Calendars and events"
    "Remove from all Google Groups"
    "Remove from all Shared Drives"
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
            break
            ;;
        "${choices[1]}")
            echo
            print_and_execute reset_password
            break
            ;;
        "${choices[2]}")
            echo
            print_and_execute reset_recovery
            break
            ;;
        "${choices[3]}")
            echo
            print_and_execute set_org_unit
            break
            ;;
        "${choices[4]}")
            echo
            print_and_execute set_endDate
            break
            ;;
        "${choices[5]}")
            echo
            print_and_execute deprovision
            break
            ;;
        "${choices[6]}")
            echo
            print_and_execute remove_directory
            break
            ;;
        "${choices[7]}")
            echo
            print_and_execute forward_emails
            break
            ;;
        "${choices[8]}")
            echo
            print_and_execute set_autoreply
            break
            ;;
        "${choices[9]}")
            echo
            print_and_execute transfer_drive
            break
            ;;
        "${choices[10]}")
            echo
            print_and_execute transfer_calendar
            break
            ;;
        "${choices[11]}")
            echo
            print_and_execute remove_groups
            break
            ;;
        "${choices[12]}")
            echo
            print_and_execute remove_drives
            break
            ;;
        *)
            echo
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
    echo | tee -a "$LOG_FILE"
    case "$yn" in
    [Yy]*) ;;
    [Nn]*) task_exit ;;
    *) print_warning "Please answer yes or no." ;;
    esac
    echo
done












entry_options=()
entries_count=${#STEP_LIST[@]}
whip_message="Navigate with the TAB key, select with the SPACE key."

# Generate options for the whiptail checklist
for i in ${!STEP_LIST[@]}; do
    if [ $((i % 2)) == 0 ]; then
        entry_options+=($(($i / 2)))
        entry_options+=("${STEP_LIST[$(($i + 1))]}")
        entry_options+=('OFF')
    fi
done

while true; do
    # Temporarily disable 'set -e' to handle whiptail exit status
    set +e
    SELECTED_STEPS_RAW=$(
        whiptail \
            --checklist \
            --separate-output \
            --title 'Offboarding' \
            "$whip_message" \
            40 80 \
            "$entries_count" -- "${entry_options[@]}" \
            3>&1 1>&2 2>&3
    )
    exitstatus=$?
    set -e

    if [[ $exitstatus -ne 0 ]]; then
        echo "User cancelled the selection. Proceeding to exit."
        break
    fi

    if [[ ! -z "$SELECTED_STEPS_RAW" ]]; then
        for STEP_FN_ID in ${SELECTED_STEPS_RAW[@]}; do
            FN_NAME_ID=$(($STEP_FN_ID * 2))
            STEP_FN_NAME="${STEP_LIST[$FN_NAME_ID]}"
            echo "---Running ${STEP_FN_NAME}---"
            $STEP_FN_NAME
        done
    else
        echo "No options selected. Proceeding to exit."
        break
    fi

    # If you cannot understand this, read Bash_Shell_Scripting/Conditional_Expressions again.
    if whiptail --title "Script exit" --yesno "Do you want to suspend the user before exiting?" 8 80; then
        echo "Proceeding to suspend user $(date)..."
        suspend
        echo "Exit status was $?."
        break
    else
        echo "Skipping user suspension, exit status was $?."
        break
    fi
done

#get_info
#reset_password
#reset_recovery
#set_endDate
#deprovision
#remove_directory
#forward_emails
#set_autoreply
#transfer_drive
#transfer_calendar
#remove_groups
#remove_drives
#set_org_unit
#suspend
end_logger

#Return to the pre-script working directory
cd $INITIAL_WORKING_DIRECTORY

#Heavily inspired by Sean Young's [deprovision.sh](https://github.com/seanism/IT/tree/5795238dc1309f245d939c89e975c805dda745f3/GAM)
