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
    #Sets path of GAM
    GAM3="/Users/$accountName/bin/gamadv-xtd3/gam"
    echo "GAM3 command alias set to ${GAM3}"
    ${GAM3} info user testbundle@grace-bible.org
    echo

) 2>&1 | tee -a "$logLocation"

cd $INITIAL_WORKING_DIRECTORY

#home is ~, current is ./, parent is ../
