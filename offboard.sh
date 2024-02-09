#!/bin/bash

#Move execution to the script parent directory
INITIAL_WORKING_DIRECTORY=$(pwd)
parent_path=$(
    cd "$(dirname "${BASH_SOURCE[0]}")"
    pwd -P
)
cd "$parent_path"

#Define variables
NOW=$(date '+%F')

accountName=$(whoami)

logDirectory=/Users/joshmckenna/Library/CloudStorage/GoogleDrive-joshmckenna@grace-bible.org/Shared\ drives/IT\ subcommittee/_ARCHIVE/gam
logFile=$logDirectory/$NOW.log

GAM3=/Users/$accountName/bin/gamadv-xtd3/gam

if [[ -n "$1" ]] && [[-n "$2" ]]; then
    offboard_user="$1"
    receiving_user="$2"
else
    echo "You ran the script without from and to emails!"
    echo ""
    echo "Input the email address of the user to offboard from Google Workspace, followed by [ENTER]"
    read offboard_user
    echo ""
    echo ""
    echo "Input the email address of the user to receive from $offboard_user, followed by [ENTER]"
    read receiving_user
    echo ""
    echo ""
fi

#Define available functions for the Whiptail menu
start_logger() {
    exec &> >(tee -a "$logFile")
    echo "========================================"
    echo "GAM3 command alias set to ${GAM3}"
    ${GAM3} version
    echo ""
}

get_info() {
    echo "Logging user's pre-offboarding info for audit..."
    ${GAM3} info user $offboard_user
    ${GAM3} user $offboard_user show forwards
    echo ""
}

unsuspend() {
    echo "Unsuspending user account for offboarding..."
    ${GAM3} update user $offboard_user suspended off
    echo ""
    echo "Waiting for suspension to be removed..."
    sleep 10
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

endlogger() {
    echo "Google Workspace deprovisioning for $offboard_user complete"
    echo "========================================"
}

#Start the global logger, begin functions
start_logger
unsuspend

#Whiptail dialog UI
STEP_LIST=(
    "get_info" "Gets the user's pre-offboarding info for audit"
    "reset_password" "Generates a random password"
    "reset_recovery" "Erasing password recovery options"
    "set_endDate" "Sets the employee directory end date"
    "deprovision" "Clears application passwords, backup verification codes, and access tokens"
    "remove_directory" "Removes employee from the Global Address List (GAL)"
    "forward_emails" "Forwarding emails, granting delegate access to manager"
    "set_autoreply" "Configures email autoreply"
    "transfer_drive" "Transfers Google Drive files"
    "transfer_calendar" "Transfers Google Calendars and events"
    "remove_groups" "Removes from all Google Groups"
    "remove_drives" "Removes from all Shared Drives"
)

entry_options=()
entries_count=${#STEP_LIST[@]}
whip_message="Choose the offboarding steps to run:"

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
endlogger

#Return to the pre-script working directory
cd $INITIAL_WORKING_DIRECTORY
