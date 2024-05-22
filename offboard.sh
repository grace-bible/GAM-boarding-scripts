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

#Define variables
NOW=$(date '+%F')
logFile=${LOG_DIR}/$NOW.log

source "$(dirname "$0")/config.env"

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
    DAYS_SINCE_LAST_UPDATE=$((($(date -d "${NOW}" +%s) - $(date -d "${GAM_LAST_UPDATE}" +%s)) / 86400))

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
if [[ $# -eq 2 ]]; then
    offboard_user="$1"
    receiving_user="$2"
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
    echo "Unsuspending user account for offboarding..."
    ${GAM3} update user $offboard_user suspended off
    echo ""
    echo "Waiting for suspension to be removed..."
    sleep 10
    echo ""
}

get_info() {
    echo "Logging user's pre-offboarding info for audit..."
    ${GAM3} info user $offboard_user
    ${GAM3} user $offboard_user show forwards
    echo ""
}

reset_password() {
    echo "Generating random password..."
    ${GAM3} update user $offboard_user password random
    ${GAM3} update user $offboard_user changepassword on
    sleep 2
    ${GAM3} update user $offboard_user changepassword off
    echo ""
}

reset_recovery() {
    echo "Erasing recovery options for $offboard_user..."
    ${GAM3} update user $offboard_user recoveryemail "" recoveryphone ""
    echo ""
}

set_endDate() {
    echo "Setting $offboard_user end date to today..."
    ${GAM3} update user $offboard_user Employment_History.End_dates multivalued $NOW
    echo ""
    #https://github.com/GAM-team/GAM/wiki/GAM3DirectoryCommands#setting-custom-user-schema-fields-at-create-or-update
}

deprovision() {
    echo "Deprovisioning application passwords, backup verification codes, and access tokens..."
    echo "Disabling POP/IMAP access, signing out all devices, and turning off MFA..."
    ${GAM3} user $offboard_user deprovision popimap signout turnoff2sv
    ${GAM3} user $offboard_user update backupcodes
    echo ""
    #https://github.com/taers232c/GAMADV-XTD3/wiki/Users-Deprovision
}

remove_directory() {
    echo "Hiding $offboard_user from the Global Address List (GAL)..."
    ${GAM3} update user $offboard_user gal off
    echo ""
    #https://github.com/GAM-team/GAM/wiki/GAM3DirectoryCommands
}

forward_emails() {
    echo "Forwarding emails, granting delegate access to manager..."
    ${GAM3} user $offboard_user print forwardingaddresses | ${GAM3} csv - gam user "~User" delete forwardingaddress "~forwardingEmail"
    ${GAM3} user $offboard_user add forwardingaddress $receiving_user
    ${GAM3} user $offboard_user forward on $receiving_user archive
    ${GAM3} user $offboard_user delegate to $receiving_user
    echo ""
    #https://github.com/taers232c/GAMADV-XTD3/wiki/Users-Gmail-Forwarding
}

set_autoreply() {
    echo "Configuring email autoreply..."
    company="Grace Bible Church"
    subject="No longer at $company"
    message="Thank you for contacting me. I am no longer working at $company. Please direct any future correspondence to $receiving_user."
    startDate=$NOW
    endDate=$(date -v +1y +%F)
    ${GAM3} user $offboard_user vacation on subject "$subject" message "$message" startdate "$startDate" enddate "$endDate"
    echo ""
}

transfer_drive() {
    echo "Transferring Drive..."
    ${GAM3} user $offboard_user transfer drive $receiving_user
    ${GAM3} create datatransfer $offboard_user gdrive $receiving_user
    echo ""
    #https://github.com/taers232c/GAMADV-XTD3/wiki/Users-Drive-Transfer
}

transfer_calendar() {
    echo "Transferring Calendar..."
    ${GAM3} calendar $offboard_user add owner $receiving_user
    ${GAM3} add datatransfer $offboard_user calendar $receiving_user releaseresources
    echo ""
}

remove_groups() {
    echo "Removing from groups..."
    ${GAM3} user $offboard_user delete groups
    echo
}

remove_drives() {
    ${GAM3} redirect csv ./SharedDriveAccess.csv multiprocess user $offboard_user print shareddrives fields id,name
    ${GAM3} redirect stdout ./DeleteSharedDriveAccess.txt multiprocess redirect stderr stdout csv ./SharedDriveAccess.csv gam delete drivefileacl ~~id~~ ~~User~~
}

set_org_unit() {
    echo "Moving $offboard_user to offboarding OU..."
    ${GAM3} update org 'Inactive' move user $offboard_user
    echo ""
}

suspend() {
    echo "Waiting for previous changes to take effect..."
    sleep 10
    ${GAM3} update user $offboard_user suspended on
}

cleanup_tmp_files() {
    rm ./SharedDriveAccess.csv
    rm ./DeleteSharedDriveAccess.txt
}

end_logger() {
    echo "Google Workspace boarding process complete"
    echo "========================================"
}

#Start the global logger, begin functions
start_logger
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
)

entry_options=()
entries_count=${#STEP_LIST[@]}
whip_message="Navigate with the TAB key, select with the SPACE key."

for i in ${!STEP_LIST[@]}; do
    if [ $((i % 2)) == 0 ]; then
        entry_options+=($(($i / 2)))
        entry_options+=("${STEP_LIST[$(($i + 1))]}")
        entry_options+=('OFF')
    fi
done

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

if [[ ! -z SELECTED_STEPS_RAW ]]; then
    for STEP_FN_ID in ${SELECTED_STEPS_RAW[@]}; do
        FN_NAME_ID=$(($STEP_FN_ID * 2))
        STEP_FN_NAME="${STEP_LIST[$FN_NAME_ID]}"
        echo "---Running ${STEP_FN_NAME}---"
        $STEP_FN_NAME
    done
fi

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
set_org_unit
suspend
end_logger

#Return to the pre-script working directory
cleanup_tmp_files
cd $INITIAL_WORKING_DIRECTORY

#Heavily inspired by Sean Young's [deprovision.sh](https://github.com/seanism/IT/tree/5795238dc1309f245d939c89e975c805dda745f3/GAM)
