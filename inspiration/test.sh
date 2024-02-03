#!/bin/bash

INITIAL_WORKING_DIRECTORY=$(pwd)

parent_path=$(
    cd "$(dirname "${BASH_SOURCE[0]}")"
    pwd -P
)

cd "$parent_path"

accountName=$(whoami)

#Define today's date and time as a variable $NOW
NOW=$(date '+%F')

#Define location for logs as a variable $logloc
logDir=/Users/joshmckenna/Library/CloudStorage/GoogleDrive-joshmckenna@grace-bible.org/Shared\ drives/IT\ subcommittee/_ARCHIVE/gam

if [ -d "$logDir" ]; then
    echo "Logging to Google Drive File Stream via joshmckenna@grace-bible.org"
    logloc=$logDir/$NOW.log
    echo
elif [ ! -d "~/GAMWork/logs/" ]; then
    echo "Setting up Logs directory"
    mkdir $logDir
    echo "Logging to $accountName/GAMWork/logs directory"
    logloc=~/GAMWork/logs/$NOW.log
else
    echo "Logging to $accountName GAMWork/logs directory"
    logloc=~/GAMWork/logs/$NOW.log
fi

(
    #Sets path of GAM
    GAM3=~/bin/gamadv-xtd3/gam
    echo "GAM3 command alias set to $GAM3"
    echo

) 2>&1 | tee -a "$logloc"

cd $INITIAL_WORKING_DIRECTORY

#home is ~, current is ./, parent is ../
