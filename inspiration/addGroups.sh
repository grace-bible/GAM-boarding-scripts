#!/bin/bash

accountName=$(whoami)

#Define today's date and time as a variable $NOW
NOW=$(date '+%F_%H:%M:%S')

#Define location for logs as a variable $logloc
logloc="/Users/${accountName}/GAMWork/logs"

(

    echo "Please enter all groups separated by commas and without any spaces"
    echo "eg ./addGroups group@domain.com,people@domain.com,test@domain.com"
    echo
    read -p "Enter email that should be added to the groups: " username
    oIFS="$IFS"
    IFS=,
    set -- $1
    IFS="$oIFS"
    for i in "$@"; do
        gam3 update group $i add member user $username
        echo "Added $username to $i"
    done
    echo "Added to: $# group(s)!"

) 2>&1 | tee -a $logloc
