#!/bin/bash

accountName=$(whoami)

#Define today's date and time as a variable $NOW
NOW=$(date '+%F')

#Define location for logs as a variable $logloc
if [ ! -d "$logDir" ]; then
    echo "Logging to Google Drive File Stream via joshmckenna@grace-bible.org"
    logloc=/Users/joshmckenna/Library/CloudStorage/GoogleDrive-joshmckenna@grace-bible.org/Shared\ drives/IT\ subcommittee/_ARCHIVE/gam/$NOW.log
    echo
else
    echo "Logging to $accountName GAMWork/logs directory"
    logloc=/Users/$accountName/GAMWork/logs/$NOW.log
fi

(
    #Sets path of GAM
    GAM3=/Users/$accountName/bin/gamadv-xtd3/gam
    echo "GAM3=$GAM3"
    echo

) 2>&1 | tee -a "$logloc"
