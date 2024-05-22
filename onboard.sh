#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Process options
while getopts :h option; do
    case $option in
    [h])
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
        echo "  4 manager_email_address     User manager email (manager@company.com)"
        echo "  5 recovery_email            Personal email for the onboarding user (email@domain.com)"
        echo "  6 campus                    Assigned campus (AND, SW, CRK, MT, SYS)"
        echo "  7 job_title                 User official job title, for use in signature (string)"
        echo "  8 birthday                  User birthday (YYYY-MM-DD) for company birthdays calendar"
        echo
        exit 0
        ;;
    \?)
        echo "Invalid option: -$OPTARG" 1>&2
        echo ""
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

# Initialize variables
NOW=$(date '+%F')
logFile=${LOG_DIR}/$NOW.log

# Function to update GAM and GAMADV-XTD3
update_gam() {
    echo "Updating GAM and GAMADV-XTD3..."
    bash <(curl -s -S -L https://gam-shortn.appspot.com/gam-install) -l
    bash <(curl -s -S -L https://raw.githubusercontent.com/taers232c/GAMADV-XTD3/master/src/gam-install.sh) -l
    # Update the last update date in the config.env file
    sed -i'' -e "s/^GAM_LAST_UPDATE=.*/GAM_LAST_UPDATE=\"${NOW}\"/" "$(dirname "$0")/config.env"
    export GAM_LAST_UPDATE="${NOW}"
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
echo "Starting onboard.sh script at $(date)"
echo "========================================"
echo "GAM3 command alias set to ${GAM3}"
${GAM3} version
echo "Logging to ${logFile}"
echo ""

#Check for arguments
if [[ $# -ge 4 ]]; then
    onboard_first_name="$1"
    onboard_last_name="$2"
    onboard_user="$3"
    manager_email_address="$4"
    recovery_email="${5:-}"
    campus="${6:-}"
    job_title="${7:-}"
    birthday="${8:-}"
    echo ""
    echo ""
else
    echo "You ran the script without adequate arguments..."
    echo ""
    read -p "Input the FIRST NAME of the new user to be provisioned in Google Workspace, followed by [ENTER]   " onboard_first_name
    echo ""
    read -p "Input the LAST NAME of the new user to be provisioned in Google Workspace, followed by [ENTER]   " onboard_last_name
    echo ""
    read -p "Input the WORK EMAIL of the new user to be provisioned in Google Workspace, followed by [ENTER]   " onboard_user
    onboard_user=$(echo "$onboard_user" | tr '[:upper:]' '[:lower:]')
    echo ""
    read -p "Input the email address of the new user's MANAGER, followed by [ENTER]   " manager_email_address
    manager_email_address=$(echo "$manager_email_address" | tr '[:upper:]' '[:lower:]')
    echo ""
    read -p "Input the PERSONAL RECOVERY EMAIL of the new user to be provisioned in Google Workspace, followed by [ENTER]   " recovery_email
    recovery_email=$(echo "$recovery_email" | tr '[:upper:]' '[:lower:]')
    echo ""
    read -p "Input the CAMPUS of the new user to be provisioned in Google Workspace, followed by [ENTER]   " campus
    echo ""
    read -p "Input the employee's JOB TITLE, followed by [ENTER]   " job_title
    echo ""
    read -p "Input the employee's BIRTHDAY (YYYY-MM-DD), followed by [ENTER]   " birthday
    echo ""
    echo ""
fi

confirm_inputs() {
    echo "Confirming inputs at $(date)"
    echo "Employee: ${onboard_first_name} ${onboard_last_name} (${onboard_user})"
    echo "Manager: ${manager_email_address}"
    echo "Recovery email: ${recovery_email}"
    echo "Campus: ${campus}"
    echo "Job title: ${job_title}"
    echo "Birthday: ${birthday}"
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

get_info() {
    echo "Entering get_info function at $(date)"
    echo "Logging newly onboarded user's info for audit..."
    ${GAM3} info user ${onboard_user}
    echo ""
    echo "Employee information retrieved."
    echo "Exiting get_info function at $(date)"
    echo ""
    echo ""
}

update_info() {
    echo "Entering update_info function at $(date)"
    echo "Updating employee organization info..."
    echo ""
    echo "Please enter the type of employee (e.g., Staff, Fellows, Mobilization, Seconded, etc.)"
    read -p "Type of employee: " type_of_employee
    echo "Employee type set to: ${type_of_employee}"
    echo ""
    read -p "Enter all associated departments, separated by commas (e.g. Youth,College,Children): " -r input
    echo ""
    IFS=',' read -r -a departments <<<"$input"
    if [[ -z "${campus}" ]]; then
        echo "The 'campus' variable is not set."
        read -p "Please enter the employee's campus: " -r campus
        echo "Campus set to: ${campus}"
    else
        echo "Campus already set to: ${campus}"
    fi
    echo "${onboard_user} is designated as ${type_of_employee} at ${campus}, assigned to these departments: ${departments[*]}"
    confirm_continue
    ${GAM3} update user ${onboard_user} relation manager ${manager_email_address} organization description "${type_of_employee}" costcenter "${campus}" department "${departments}" title "${job_title}" primary
    echo "Employee information updated."
    echo "Exiting update_info function at $(date)"
    echo ""
    echo ""
}

create_user() {
    echo "Entering create_user function at $(date)"
    echo "Creating new user with email ${onboard_user}..."
    ${GAM3} create user ${onboard_user} firstname ${onboard_first_name} lastname ${onboard_last_name} org New\ users notify ${recovery_email},${CC_HR} subject "[ACTION REQUIRED] Activate your #email# email" password "${TEMP_PASS}" notifypassword "${TEMP_PASS}" changepasswordatnextlogin
    echo "...setting employment start date..."
    ${GAM3} update user ${onboard_user} Employment_History.Start_dates multivalued ${NOW} #https://github.com/GAM-team/GAM/wiki/GAM3DirectoryCommands#setting-custom-user-schema-fields-at-create-or-update
    echo "...adding to staff birthday calendar..."
    ${GAM3} calendar ${onboard_user} addevent attendee ${BDAY_CAL} start allday "${birthday}" end allday "${birthday}" summary "${onboard_first_name} ${onboard_last_name}'s birthday!" recurrence "RRULE:FREQ=YEARLY" transparency transparent #https://github.com/GAM-team/GAM/wiki/Command-Reference:-Calendars#gam-who-add--update-calendar-calendar-email
    echo "Emailed credentials to ${recovery_email} and ${CC_HR}"
    echo "New user account for ${onboard_user} created."
    echo "Exiting create_user function at $(date)"
    echo ""
    echo ""
}

view_signature() {
    echo "Entering view_signature function at $(date)"
    echo "Fetching the current user email signature..."
    echo "Here's the ${onboard_user}'s current email signature:"
    ${GAM3} user ${onboard_user} show signature format
    echo "Current email signature retrieved."
    echo "Exiting view_signature function at $(date)"
    echo ""
    echo ""
}

set_signature() {
    echo "Entering set_signature function at $(date)"
    if [ -z "${job_title:-}" ]; then
        read -p "Enter the onboard user's job title: " -r job_title
    fi
    echo "Setting up email signature..."
    ${GAM3} user ${onboard_user} signature file ${SIG_FILE} replace NAME "${onboard_first_name} ${onboard_last_name}" replace TITLE "${job_title}"
    echo "Signature set."
    read -p "Do you want to view the signature to confirm it was set properly? (y/n): " -r response
    case "$response" in
    [Yy]*)
        echo ""
        echo ""
        view_signature
        ;;
    [Nn]*)
        echo "Signature view skipped."
        ;;
    *)
        echo "Invalid response. Signature view skipped."
        ;;
    esac
    echo "Exiting set_signature function at $(date)"
    echo ""
    echo ""
}

add_groups() {
    echo "Entering add_groups function at $(date)"
    echo "Adding user to groups..."

    read -p "Please enter all groups separated by commas (e.g., group1@domain.com,group2@domain.com): " groups_input
    echo "Groups input: ${groups_input}"
    groups_input=$(echo "$groups_input" | tr '[:upper:]' '[:lower:]')
    IFS=',' read -r -a groups <<<"$groups_input"

    for group in "${groups[@]}"; do
        read -p "Enter the permission level for $group (e.g., MEMBER, MANAGER, OWNER): " permission
        permission=$(echo "$permission" | tr '[:upper:]' '[:lower:]')
        echo "Adding ${onboard_user} to ${group} as ${permission}"
        case "$permission" in
        MEMBER | MANAGER | OWNER)
            if ${GAM3} update group "${group}" add "${permission}" user "${onboard_user}"; then
                echo "Successfully added ${onboard_user} to ${group} as a ${permission}."
            else
                echo "Error: Failed to add ${onboard_user} to ${group}" >&2
            fi
            ;;
        *)
            echo "Invalid permission level: ${permission}. Valid options are MEMBER, MANAGER, OWNER." >&2
            ;;
        esac
    done

    echo "User added to all specified groups."
    echo "Exiting add_groups function at $(date)"
    echo ""
    echo ""
}

end_logger() {
    echo "Google Workspace boarding process complete"
    echo ""
    echo "========================================"
}

# Whiptail dialog UI
STEP_LIST=(
    "get_info" "Print info for an existing user account"
    "update_info" "Set details: manager, campus, department, job title"
    "create_user" "Create a new user account"
    "view_signature" "Print an existing user email signature"
    "set_signature" "Configure a standard format email signature"
    "add_groups" "Add user to new groups"
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
            --title 'Onboarding' \
            "$whip_message" \
            20 78 10 \
            "${entry_options[@]}" \
            3>&1 1>&2 2>&3
    )
    exitstatus=$?
    set -e

    if [[ $exitstatus -ne 0 ]]; then
        echo "User cancelled the selection. Exiting script."
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
        echo "No options selected. Exiting script."
        break
    fi

    # Optionally, ask if the user wants to perform more tasks
    if ! whiptail --yesno "Do you want to perform more tasks?" 10 60; then
        break
    fi
done

#set_password
#create_user
#employment_status
#set_campus
#set_departments
#update_info
#set_signature
#add_groups
#get_info
end_logger

cd $INITIAL_WORKING_DIRECTORY
