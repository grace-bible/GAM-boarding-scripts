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

#https://github.com/GAM-team/GAM/wiki/CalendarExamples

#Check for arguments
if [[ $# -eq 3 ]]; then
    calendars="$1"
    onboard_user="$2"
    permission="$3"
else
    echo "Please enter all calendar addresses separated by commas and without any spaces."
    echo "(e.g. calendar@domain.com,othercalendar@domain.com,test@domain.com), followed by [ENTER]"
    echo ""
    read calendars
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

# Function to handle errors gracefully
error_exit() {
    echo "Error: $1" >&2
    exit 1
}

# Validate email address
validate_email() {
    # Implement your email validation logic here
    # Example: use a regular expression to check for valid email format
    [[ $1 =~ ^[^@]+@[^@]+\.[^@]+$ ]] || error_exit "Invalid email address: $1"
}

endlogger() {
    echo "Google Workspace changes complete"
    echo "========================================"
}

#Start the global logger, begin functions
start_logger

echo "--------------------BEFORE--------------------"
${GAM3} user ${onboard_user} show calendars
echo "--------------------BEFORE--------------------"

while true; do
    validate_email $onboard_user && break
    echo "Invalid email address. Please try again."
    read -p "Enter the user that should be added to the calendars, followed by [ENTER]   " onboard_user
    echo ""
    echo "What is the permission level for ${onboard_user} on these calendars?"
    read -p "editor | freebusy | freebusyreader | owner | reader | writer | none   " permission
done
echo ""

oIFS="$IFS"
IFS=,
set -- $1
IFS="$oIFS"
for i in "$@"; do
    ${GAM3} calendar $i add ${permission} ${onboard_user} sendnotifications false || error_exit "Failed to update setttings for $i"
    echo "Successfully updated settings for $i"
done
echo "Updated: $# calendar(s)!"
echo ""
sleep 10

echo "--------------------AFTER--------------------"
${GAM3} user ${onboard_user} show calendars
echo "--------------------AFTER--------------------"

endlogger

#Return to the pre-script working directory
cd $INITIAL_WORKING_DIRECTORY
