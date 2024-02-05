#!/bin/bash

INITIAL_WORKING_DIRECTORY=$(pwd)

parent_path=$(
    cd "$(dirname "${BASH_SOURCE[0]}")"
    pwd -P
)

cd "$parent_path"

accountName=joshmckenna

#Define today's date and time as a variable $NOW
NOW=$(date '+%F')

#Define location for logs as a variable $logLocation
logDirectory=/Users/joshmckenna/Library/CloudStorage/GoogleDrive-joshmckenna@grace-bible.org/Shared\ drives/IT\ subcommittee/_ARCHIVE/gam

if [ -d "$logDirectory" ]; then
    echo "Logging to Google Drive File Stream via joshmckenna@grace-bible.org"
    logLocation=$logDirectory/$NOW.log
    echo
elif [ ! -d "/Users/$accountName/GAMWork/logs/" ]; then
    echo "Setting up Logs directory"
    mkdir $logDirectory
    echo "Logging to /Users/$accountName/GAMWork/logs directory"
    logLocation=/Users/$accountName/GAMWork/logs/$NOW.log
else
    echo "Logging to /Users/$accountName/GAMWork/logs directory"
    logLocation=/Users/$accountName/GAMWork/logs/$NOW.log
fi

(
    GAM3=/Users/$accountName/bin/gamadv-xtd3/gam
    echo "========================================"
    echo "GAM3 command alias set to ${GAM3}"
    echo
    echo

    echo "Input the email address of the user to offboard from Google Workspace, followed by [ENTER]"
    read offboard_user
    echo
    echo

    echo "Logging user's pre-offboarding info for audit..."
    ${GAM3} info user $offboard_user
    ${GAM3} user $offboard_user show forwards
    echo
    echo "Unsuspending user account for offboarding..."
    ${GAM3} update user $offboard_user suspended off
    echo
    echo "Waiting 10 seconds for suspension to be removed..."
    sleep 10
    echo
    echo "Generating random password..."
    ${GAM3} update user $offboard_user password random
    echo
    echo "Hiding $offboard_user from the Global Address List (GAL)..."
    ${GAM3} update user $offboard_user gal off #https://github.com/GAM-team/GAM/wiki/GAM3DirectoryCommands
    echo
    echo "Erasing recovery options for $offboard_user..."
    ${GAM3} update user $offboard_user recoveryemail "" recoveryphone ""
    echo
    echo "Setting $offboard_user end date to today..."
    ${GAM3} update user $offboard_user Employment_History.End_dates multivalued $NOW #https://github.com/GAM-team/GAM/wiki/GAM3DirectoryCommands#setting-custom-user-schema-fields-at-create-or-update
    echo
    echo "Deprovisioning application passwords, backup verification codes, and access tokens..."
    echo "Disabling POP/IMAP access, signing out all devices, and turning off MFA..."
    ${GAM3} user $offboard_user deprovision popimap signout turnoff2sv #https://github.com/taers232c/GAMADV-XTD3/wiki/Users-Deprovision
    ${GAM3} user $offboard_user update backupcodes
    echo
    echo

    echo "Input the email address of the user to receive from $offboard_user, followed by [ENTER]"
    read receiving_user
    echo
    echo

    echo "Forwarding emails..."
    company="Grace Bible Church"
    subject="No longer at Grace Bible Church"
    message="Thank you for contacting me. I am no longer working at $company. Please direct any future correspondence to $receiving_user."
    ${GAM3} user $offboard_user print forwardingaddresses | ${GAM3} csv - gam user "~User" delete forwardingaddress "~forwardingEmail"
    ${GAM3} user $offboard_user add forwardingaddress $receiving_user
    ${GAM3} user $offboard_user forward on $receiving_user archive #https://github.com/taers232c/GAMADV-XTD3/wiki/Users-Gmail-Forwarding
    echo
    echo "Configuring email autoreply..."
    startDate=$NOW
    endDate=$(date -v +1y +%F)
    ${GAM3} user $offboard_user vacation on subject "$subject" message "$message" startdate "$startDate" enddate "$endDate"
    echo
    echo "Transferring Drive..."
    ${GAM3} user $offboard_user transfer drive $receiving_user #https://github.com/taers232c/GAMADV-XTD3/wiki/Users-Drive-Transfer
    echo
    echo "Transferring Calendar..."
    ${GAM3} calendar $offboard_user add owner $receiving_user
    ${GAM3} add datatransfer $offboard_user calendar $receiving_user releaseresources
    echo
    echo "Removing from groups..."
    ${GAM3} user $offboard_user delete groups
    echo
    echo "Moving $username to Offboarding OU..."
    ${GAM3} update user $username org Inactive
    echo
    echo
    echo "Waiting for previous changes to take effect..."
    sleep 10
    ${GAM3} update user $offboard_user suspended on

    echo "Google Workspace deprovisioning for $offboard_user complete"
    echo "========================================"

) 2>&1 | tee -a "$logLocation"

cd $INITIAL_WORKING_DIRECTORY
