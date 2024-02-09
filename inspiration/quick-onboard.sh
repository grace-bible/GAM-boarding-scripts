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

sigFile=/Users/joshmckenna/repos/GAM-boarding-scripts/dependencies/signature.txt
onboard_manager=janineford@grace-bible.org,joshmckenna@grace-bible.org
TEMP_PASS=P@ssw0rdy

onboard_first_name=$1
onboard_last_name=$2
onboard_user=$3
recovery_email=$4
campus=$5
job_title=$6

confirm_inputs() {
    echo "Employee: ${onboard_first_name} ${onboard_first_name} ${onboard_user}"
    echo "Job title: ${job_title}"
    wait 2

    read -p "Press any key to continue... " -n1 -s
    echo ""
}

start_logger() {
    exec &> >(tee -a "$logFile")
    echo "========================================"
    echo "GAM3 command alias set to ${GAM3}"
    ${GAM3} version
    echo ""
}

end_logger() {
    echo "Google Workspace boarding process complete"
    echo "Emailed credentials to $recovery_email and $onboard_manager"
    echo "Locally, you can find the log at: ${logFile}"
    echo ""
    echo "========================================"
}

read -p "Input a temporary password for the user, followed by [ENTER]: " TEMP_PASS
echo ""

read -p "Input the employee's primary department, followed by [ENTER]: " department
echo ""

read -p "Input the employee responsible for onboarding, followed by [ENTER]: " onboard_manager
echo ""

confirm_inputs

start_logger

${GAM3} create user $onboard_user firstname $onboard_first_name lastname $onboard_last_name org New\ users notify $recovery_email,$onboard_manager subject "[ACTION REQUIRED] Activate your #email# email" password "${TEMP_PASS}" notifypassword "${TEMP_PASS}" changepasswordatnextlogin
echo
${GAM3} update user $onboard_user Employment_History.Start_dates multivalued $NOW
${GAM3} update user $onboard_user organization description "$department" costcenter "$campus" title "$job_title" primary
echo
${GAM3} user $onboard_user signature file $sigFile replace NAME "$onboard_first_name $onboard_last_name" replace TITLE "$job_title"
${GAM3} user $onboard_user show signature format
echo
${GAM3} info user $onboard_user

end_logger
