#!/bin/bash
# set -euo pipefail
# IFS=$'\n\t'

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

#https://github.com/taers232c/GAMADV-XTD3/wiki/Groups

#Check for arguments
if [[ $# -eq 3 ]]; then
    onboard_user="$2"
    groups="$1"
    permission="$3"
else
    echo "Please enter all groups separated by commas and without any spaces."
    echo "(e.g. group@domain.com,people@domain.com,test@domain.com), followed by [ENTER]"
    echo ""
    read groups
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

end_logger() {
    echo ""
    echo "Google Workspace boarding process complete"
    echo "========================================"
}

#Start the global logger, begin functions
start_logger

echo "--------------------BEFORE--------------------"
${GAM3} user ${onboard_user} show groups
echo "--------------------BEFORE--------------------"
echo ""
read -p "Press any key to continue... " -n1 -s
echo ""

# while true; do
#     validate_email $onboard_user && break
#     echo "Invalid email address. Please try again."
#     read -p "Enter email that should be added to the groups, followed by [ENTER]:   " onboard_user
#     read -p "Enter the group membership type, either Member, Manager, or Owner, followed by [ENTER]:   " role
# done
# echo

oIFS="$IFS"
IFS=,
set -- $1
IFS="$oIFS"
for i in "$@"; do
    ${GAM3} update group $i add ${permission} user ${onboard_user} || error_exit "Failed to add user to group: $i"
    echo "Added $onboard_user to $i"
done
echo "Added to: $# group(s)!"
echo ""
sleep 10

echo "--------------------AFTER--------------------"
${GAM3} user ${onboard_user} show groups
echo "--------------------AFTER--------------------"

end_logger

#Return to the pre-script working directory
cd $INITIAL_WORKING_DIRECTORY
