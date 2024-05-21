#!/bin/bash
# set -euo pipefail
# IFS=$'\n\t'

# Move execution to the script's parent directory
INITIAL_WORKING_DIRECTORY=$(pwd)
parent_path=$(
    cd "$(dirname "${BASH_SOURCE[0]}")"
    pwd -P
)
cd "$parent_path"

# Initialize variables
NOW=$(date '+%F')
accountName=$(whoami)
logDirectory=/Users/joshmckenna/Library/CloudStorage/GoogleDrive-joshmckenna@grace-bible.org/Shared\ drives/IT\ subcommittee/_ARCHIVE/gam
logFile=$logDirectory/$NOW.log
GAM3=/Users/$accountName/bin/gamadv-xtd3/gam
sigFile=/Users/joshmckenna/repos/GAM-boarding-scripts/dependencies/signature.txt
TEMP_PASS=$(openssl rand -base64 12)

onboard_manager=janineford@grace-bible.org,joshmckenna@grace-bible.org
birthday_calendar=grace-bible.org_2lncaimlf8ua413n1v7pkmere4@group.calendar.google.com

# Ensure the log directory exists
mkdir -p "${logDirectory}"

# Start logging
exec &> >(tee -a "$logFile")
echo "========================================"
echo "GAM3 command alias set to ${GAM3}"
${GAM3} version
echo "Logging to ${logFile}"
echo ""

# Define functions for each onboarding step
set_password() {
    echo "Setting a custom temporary password..."
    read -p "Do you want to set a custom temporary password? (Y/N) " yn
    case $yn in
    [Yy]*)
        read -s -p "Input the user temporary password, followed by [ENTER]: " TEMP_PASS
        ;;
    [Nn]*)
        echo "Proceeding with the default password: ${TEMP_PASS}"
        ;;
    *)
        echo "Invalid response."
        return 1
        ;;
    esac
    echo "Temporary password set."
}

create_user() {
    echo "Creating new user..."
    ${GAM3} create user ${onboard_user} firstname ${onboard_first_name} lastname ${onboard_last_name} org New\ users notify ${recovery_email},${onboard_manager} subject "[ACTION REQUIRED] Activate your #email# email" password "${TEMP_PASS}" notifypassword "${TEMP_PASS}" changepasswordatnextlogin
    echo "...setting employment start date..."
    ${GAM3} update user ${onboard_user} Employment_History.Start_dates multivalued ${NOW} #https://github.com/GAM-team/GAM/wiki/GAM3DirectoryCommands#setting-custom-user-schema-fields-at-create-or-update
    echo "...adding to staff birthday calendar..."
    ${GAM3} calendar ${onboard_user} addevent attendee ${birthday_calendar} start allday "${birthday}" end allday "${birthday}" summary "${onboard_first_name} ${onboard_last_name}'s birthday!" recurrence "RRULE:FREQ=YEARLY" transparency transparent #https://github.com/GAM-team/GAM/wiki/Command-Reference:-Calendars#gam-who-add--update-calendar-calendar-email
    echo "New user account created."
    echo ""
    echo ""
}

update_info() {
    echo "Updating employee organization info..."
    ${GAM3} update user ${onboard_user} relation manager ${manager_email_address} organization description "${type_of_employee}" costcenter "${campus}" department "${department}" title "${job_title}" primary
    echo "Employee information updated."
    echo ""
}

set_signature() {
    echo "Setting up email signature..."
    ${GAM3} user ${onboard_user} signature file ${sigFile} replace NAME "${onboard_first_name} ${onboard_last_name}" replace TITLE "${job_title}"
    echo "Signature set."
    echo ""
}

view_signature() {
    echo "Fetching the current user email signature..."
    echo "Here's the ${onboard_user}'s current email signature:"
    ${GAM3} user ${onboard_user} show signature format
    echo ""
}

add_groups() {
    echo "Adding user to groups..."
    echo "...adding to all@grace-bible.org..."
    ${GAM3} update group all@grace-bible.org add member ${onboard_user}
    echo "...adding to ${type_of_employee}@grace-bible.org..."
    ${GAM3} update group ${type_of_employee}@grace-bible.org add member ${onboard_user}
    # echo "...adding to ..."
    # ${GAM3} update group ${campus}${type_of_employee}@grace-bible.org add member ${onboard_user}
    # echo "...adding to ${campus}${department}${type_of_employee}@grace-bible.org..."
    # ${GAM3} update group ${campus}${department}${type_of_employee}@grace-bible.org add member ${onboard_user}
    echo "Adding user to ${campus} campus ${type_of_employee} email Groups."
    echo "User added to groups."
    echo ""
}

get_info() {
    echo "Logging newly onboarded user's info for audit..."
    ${GAM3} info user ${onboard_user}
    echo ""
}

end_logger() {
    echo "Google Workspace boarding process complete"
    echo "Emailed credentials to $recovery_email and $onboard_manager"
    echo "Locally, you can find the log at: ${logFile}"
    echo ""
    echo "========================================"
}

# Help function for the script
help_function() {
    echo "This script automates the process of onboarding new users in Google Workspace. It uses the Google Apps Manager (GAMADV-XTD3) command-line tool to interact with Google Workspace APIs."
    echo
    echo "Syntax: onboard [-h] [<onboard_first_name> <onboard_last_name> <recovery_email> <onboard_user> <job_title> <manager_email_address> <birthday>]"
    echo
    echo "options:"
    echo "  h                       Print this help."
    echo "arguments:"
    echo "  1 onboard_first_name        User first name (string)"
    echo "  2 onboard_last_name         User last name (string)"
    echo "  3 onboard_user              User new domain email (user@company.com)"
    echo "  4 recovery_email            Personal email for the onboarding user (email@domain.com)"
    echo "  5 campus                    Assigned campus (AND, SW, CRK, MT, SYS)"
    echo "  6 job_title                 User official job title, for use in signature (string)"
    echo "  7 manager_email_address     User manager email (manager@company.com)"
    echo "  8 birthday                  User birthday (YYYY-MM-DD) for company birthdays calendar"
    echo
}

# Process options
while getopts :h option; do
    case $option in
    [h])
        help_function
        exit 0
        ;;
    \?)
        echo "Invalid Option: -$OPTARG" 1>&2
        echo ""
        exit 1
        ;;
    esac
done

#Check for arguments
if [[ $# -eq 8 ]]; then
    onboard_first_name="$1"
    onboard_last_name="$2"
    onboard_user="$3"
    recovery_email="$4"
    campus="$5"
    job_title="$6"
    manager_email_address="$7"
    birthday="$8"
else
    echo "You ran the script without adequate arguments..."
    echo ""
    read -p "Input the FIRST NAME of the new user to be provisioned in Google Workspace, followed by [ENTER]   " onboard_first_name
    echo ""
    echo ""
    read -p "Input the LAST NAME of the new user to be provisioned in Google Workspace, followed by [ENTER]   " onboard_last_name
    echo ""
    echo ""
    read -p "Input the WORK EMAIL of the new user to be provisioned in Google Workspace, followed by [ENTER]   " onboard_user
    echo ""
    echo ""
    read -p "Input the PERSONAL RECOVERY EMAIL of the new user to be provisioned in Google Workspace, followed by [ENTER]   " recovery_email
    echo ""
    echo ""
    read -p "Input the CAMPUS of the new user to be provisioned in Google Workspace, followed by [ENTER]   " campus
    echo ""
    echo ""
    read -p "Input the employee's JOB TITLE, followed by [ENTER]   " job_title
    echo ""
    echo ""
    read -p "Input the email address of the new user's MANAGER, followed by [ENTER]   " manager_email_address
    echo ""
    echo ""
    read -p "Input the employee's BIRTHDAY (YYYY-MM-DD), followed by [ENTER]   " birthday
    echo ""
    echo ""
fi

confirm_inputs() {
    echo "Employee: ${onboard_first_name} ${onboard_last_name} ${onboard_user}"
    echo "User activation sent to ${recovery_email}"
    echo "Campus: ${campus}"
    echo "Job title: ${job_title}"
    echo "Manager: ${manager_email_address}"
    echo "Birthday: ${birthday}"
    sleep 2
}

confirm_continue() {
    echo ""
    read -p "Press any key to continue... " -n1 -s
    echo ""
}

confirm_inputs
confirm_continue

#Start the global logger, begin functions
start_logger

#Whiptail dialog UI
STEP_LIST=(
    "set_password" "Set a custom temporary password"
    "create_user" "Create a new user account"
    "employment_status" "Set the user's employment status"
    "set_campus" "Set the employee's assigned campus"
    "set_department" "Clear app passwords, backup codes, and access tokens"
    "update_info" "Remove user from Global Address List (GAL)"
    "set_signature" "Forward emails, grant delegate access recipient"
    "add_groups" "Configure email autoreply"
    "get_info" "Transfer Google Drive files"
    "remove_groups" "Remove from all Google Groups"
    "remove_drives" "Remove from all Shared Drives"
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

set_password
#create_user
#employment_status
#set_campus
#set_department
#update_info
#set_signature
#add_groups
get_info
end_logger

cd $INITIAL_WORKING_DIRECTORY

employment_status() {
    echo "What type of employee is this?"
    echo "Options include..."
    echo "Staff, Fellows, Mobilization, Non-staff (MOU, seconded, lay leader, etc.)"
    echo ""
    read type_of_employee
    echo ""
}

set_campus() {
    echo "What is the employee's reporting campus?"
    echo "Options include..."
    echo "AND, SW, CRK, MT, SYS, KK"
    echo ""
    read campus
    echo ""
}

set_department() {
    echo "What is (are) the employee's department(s)?"
    echo "Please enter departments separated by commas and without any spaces"
    echo "e.g Grace56, Youth, YI, College, Junction, GO, Mobilization, etc."
    echo ""
    read department
    echo ""
}
