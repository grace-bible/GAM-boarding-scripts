#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

while getopts :h option; do
    case $option in
    [h])
        echo "This script automates the process of onboarding new users in Google Workspace. It uses the Google Apps Manager (GAMADV-XTD3) command-line tool to interact with Google Workspace APIs."
        echo
        echo "Syntax: offboard [-h] [<offboard_user> <receiving_user>]"
        echo
        echo "options:"
        echo "  h                 Print this help."
        echo "arguments:"
        echo "  1 offboard_user     User email for the offboarding user"
        echo "  2 receiving_user    User email for the receiving user of any transfers"
        echo
        exit 0
        ;;
    \?)
        echo "Invalid option: -$OPTARG" 1>&2
        exit 1
        ;;
    esac
done

# Move execution to the script's parent directory
INITIAL_WORKING_DIRECTORY=$(pwd)
parent_path=$(
    cd "$(dirname "${BASH_SOURCE[0]}")"
    pwd -P
)
cd "$parent_path"

source "$(dirname "$0")/config.env"

#Define variables
NOW=$(date '+%F')
logFile=${LOG_DIR}/$NOW.log

# Function to update GAM and GAMADV-XTD3
update_gam() {
    echo "Updating GAM and GAMADV-XTD3..."
    bash <(curl -s -S -L https://gam-shortn.appspot.com/gam-install) -l
    bash <(curl -s -S -L https://raw.githubusercontent.com/taers232c/GAMADV-XTD3/master/src/gam-install.sh) -l
    # Update the last update date in the config.env file
    local current_date=$(date +%F)
    sed -i'' -e "s/^GAM_LAST_UPDATE=.*/GAM_LAST_UPDATE=\"$current_date\"/" "$(dirname "$0")/config.env"
    export GAM_LAST_UPDATE="$current_date"
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

# Start logging
exec &> >(tee -a "$logFile")
echo "========================================"
echo "Starting offboard.sh script at $(date)"
echo "========================================"
echo "GAM3 command alias set to ${GAM3}"
${GAM3} version
echo "Logging to ${logFile}"
echo ""

# Define available functions for the Whiptail menu

#Check for arguments
if [[ $# -ge 1 ]]; then
    offboard_user="$1"
    receiving_user="${2:-}"
else
    echo "You ran the script without adequate arguments..."
    echo ""
    read -p "Input the email address of the USER TO OFFBOARD from Google Workspace, followed by [ENTER]   " offboard_user
    offboard_user=$(echo "$offboard_user" | tr '[:upper:]' '[:lower:]')
    echo ""
    read -p "Input the email address of the USER TO RECEIVE from ${offboard_user}, followed by [ENTER]   " receiving_user
    receiving_user=$(echo "$receiving_user" | tr '[:upper:]' '[:lower:]')
    echo ""
    echo ""
fi

confirm_inputs() {
    echo "Confirming inputs at $(date)"
    echo "Employee to offboard: ${offboard_user}"
    echo "Employee to receive transfers: ${receiving_user}"
    echo "Inputs confirmed."
    echo ""
    sleep 2
}

confirm_continue() {
    echo "Press any key to continue..."
    read -n1 -s
    echo "Continuing execution at $(date)"
    echo ""
}

confirm_inputs
confirm_continue

unsuspend() {
    echo "Entering unsuspend function at $(date)"
    echo "Unsuspending user account for offboarding..."
    ${GAM3} update user $offboard_user suspended off
    echo ""
    echo "Waiting for suspension to be removed..."
    sleep 10
    echo "Ready to continue!"
    echo ""
    echo ""
}

get_info() {
    echo "Entering get_info function at $(date)"
    echo "Logging ${offboard_user}'s pre-offboarding info for audit..."
    ${GAM3} info user $offboard_user
    echo "Showing email forwards for ${offboard_user}..."
    ${GAM3} user $offboard_user show forwards
    echo "Showing Shared Drives for ${offboard_user}..."
    ${GAM3} user $offboard_user show teamdrives
    echo "Showing calendars for ${offboard_user}..."
    ${GAM3} user $offboard_user show calendars
    echo "${offboard_user}'s pre-offboarding info logged."
    echo "Exiting get_info function at $(date)"
    echo ""
    echo ""
}

reset_password() {
    echo "Entering reset_password function at $(date)"
    echo "Generating random password..."
    ${GAM3} update user $offboard_user password random
    echo "Requiring password change on next login..."
    ${GAM3} update user $offboard_user changepassword on
    sleep 2
    ${GAM3} update user $offboard_user changepassword off
    echo "${offboard_user}'s password changed."
    echo "Exiting reset_password function at $(date)"
    echo ""
    echo ""
}

reset_recovery() {
    echo "Entering reset_recovery function at $(date)"
    echo "Erasing recovery options for $offboard_user..."
    ${GAM3} update user $offboard_user recoveryemail "" recoveryphone ""
    echo "Exiting reset_recovery function at $(date)"
    echo ""
    echo ""
}

set_endDate() {
    echo "Entering set_endDate function at $(date)"
    echo "Setting ${offboard_user} end date to today..."
    ${GAM3} update user $offboard_user Employment_History.End_dates multivalued $NOW
    echo "${offboard_user}'s end date set."
    echo "Exiting set_endDate function at $(date)"
    echo ""
    echo ""
    #https://github.com/GAM-team/GAM/wiki/GAM3DirectoryCommands#setting-custom-user-schema-fields-at-create-or-update
}

deprovision() {
    echo "Entering deprovision function at $(date)"
    echo "Deprovisioning application passwords, backup verification codes, and access tokens..."
    echo "Disabling POP/IMAP access, signing out all devices, and turning off MFA..."
    ${GAM3} user $offboard_user deprovision popimap signout turnoff2sv
    echo "Generating new MFA backup codes..."
    ${GAM3} user $offboard_user update backupcodes
    echo "${offboard_user} has been deprovisioned."
    echo "Exiting deprovision function at $(date)"
    echo ""
    echo ""
    #https://github.com/taers232c/GAMADV-XTD3/wiki/Users-Deprovision
}

remove_directory() {
    echo "Entering remove_directory function at $(date)"
    echo "Hiding ${offboard_user} from the Global Address List (GAL)..."
    ${GAM3} update user $offboard_user gal off
    echo "${offboard_user} has been removed from the Global Address List (GAL)."
    echo "Exiting remove_directory function at $(date)"
    echo ""
    echo ""
    #https://github.com/GAM-team/GAM/wiki/GAM3DirectoryCommands
}

forward_emails() {
    echo "Entering forward_emails function at $(date)"
    echo "Forwarding emails, granting delegate access to manager..."
    ${GAM3} user $offboard_user print forwardingaddresses | ${GAM3} csv - gam user "~User" delete forwardingaddress "~forwardingEmail"
    echo "User-configured forwarding for ${offboard_user} has been deleted..."
    ${GAM3} user $offboard_user add forwardingaddress $receiving_user
    echo "Email for ${offboard_user} has been forwarded to ${receiving_user}..."
    ${GAM3} user $offboard_user forward on $receiving_user archive
    echo "Set ${offboard_user} inbox to archive after forwarding..."
    ${GAM3} user $offboard_user delegate to $receiving_user
    echo "Email for ${offboard_user} has been delegated to ${receiving_user}..."
    echo "Deleting ${offboard_user}'s email aliases..."
    ${GAM3} user $offboard_user delete aliases
    echo "${offboard_user}'s email aliases were deleted."
    echo "Exiting forward_emails function at $(date)"
    echo ""
    echo ""
    #https://github.com/taers232c/GAMADV-XTD3/wiki/Users-Gmail-Forwarding
}

set_autoreply() {
    echo "Entering set_autoreply function at $(date)"
    echo "Configuring email autoreply..."
    company="Grace Bible Church"
    subject="No longer at $company"
    echo "Subject: ${subject}"
    message="Thank you for contacting me. I am no longer working at $company. Please direct any future correspondence to $receiving_user."
    echo "Message: ${message}"
    startDate=$NOW
    endDate=$(date -v +1y +%F)
    echo "Autoreply set until: ${endDate}"
    ${GAM3} user $offboard_user vacation on subject "$subject" message "$message" startdate "$startDate" enddate "$endDate"
    echo "Email autoreply for ${offboard_user} set."
    echo "Exiting set_autoreply function at $(date)"
    echo ""
    echo ""
}

transfer_drive() {
    echo "Entering transfer_drive function at $(date)"
    echo "Transferring Drive..."
    ${GAM3} user $offboard_user transfer drive $receiving_user
    ${GAM3} create datatransfer $offboard_user gdrive $receiving_user
    echo "${offboard_user}'s My Drive was transferred to ${receiving_user}"
    echo "Exiting transfer_drive function at $(date)"
    echo ""
    echo ""
    #https://github.com/taers232c/GAMADV-XTD3/wiki/Users-Drive-Transfer
}

transfer_calendar() {
    echo "Entering transfer_calendar function at $(date)"
    echo "Transferring Calendar..."
    ${GAM3} calendar $offboard_user add owner $receiving_user
    ${GAM3} add datatransfer $offboard_user calendar $receiving_user releaseresources
    echo "${offboard_user}'s calendar was transferred to ${receiving_user}"
    echo "Exiting transfer_calendar function at $(date)"
    echo ""
    echo ""
}

remove_groups() {
    echo "Entering remove_groups function at $(date)"
    echo "Removing from groups..."
    ${GAM3} user $offboard_user delete groups
    echo "${offboard_user} removed from groups."
    echo "Exiting remove_groups function at $(date)"
    echo ""
    echo ""
}

remove_drives() {
    echo "Entering remove_drives function at $(date)"
    echo "Removing from Shared Drives..."
    ${GAM3} redirect csv ./SharedDriveAccess.csv multiprocess user $offboard_user print shareddrives fields id,name
    ${GAM3} redirect stdout ./DeleteSharedDriveAccess.txt multiprocess redirect stderr stdout csv ./SharedDriveAccess.csv gam delete drivefileacl ~~id~~ ~~User~~
    echo "${offboard_user} removed from Shared Drives."
    echo "Cleaning up temporary files..."
    rm ./SharedDriveAccess.csv
    rm ./DeleteSharedDriveAccess.txt
    echo "Temporary files deleted."
    echo "Exiting remove_drives function at $(date)"
    echo ""
    echo ""
}

set_org_unit() {
    echo "Entering set_org_unit function at $(date)"
    echo "Moving $offboard_user to offboarding OU..."
    ${GAM3} update org 'Inactive' move user $offboard_user
    echo "${offboard_user} moved to Inactive OU."
    echo "Exiting set_org_unit function at $(date)"
    echo ""
    echo ""
}

suspend() {
    echo "Waiting for previous changes to take effect..."
    sleep 10
    ${GAM3} update user $offboard_user suspended on
    echo "${offboard_user} was suspended."
    echo ""
    echo ""
}

end_logger() {
    echo "Google Workspace boarding process complete"
    echo ""
    echo "========================================"
    echo "========================================"
}

unsuspend

#Whiptail dialog UI
STEP_LIST=(
    "get_info" "Get user pre-offboarding info for audit"
    "reset_password" "Generate a random password"
    "reset_recovery" "Erase password recovery options"
    "set_endDate" "Set employee end date in directory"
    "deprovision" "Clear app passwords, backup codes, and access tokens"
    "remove_directory" "Remove user from Global Address List (GAL)"
    "forward_emails" "Forward emails, grant delegate access recipient"
    "set_autoreply" "Configure email autoreply"
    "transfer_drive" "Transfer Google Drive files"
    "transfer_calendar" "Transfer Google Calendars and events"
    "remove_groups" "Remove from all Google Groups"
    "remove_drives" "Remove from all Shared Drives"
    "set_org_unit" "Move user to Inactive OU"
)

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
