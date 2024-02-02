#!/bin/bash

accountName=$(whoami)

#Define today's date and time as a variable $NOW
NOW=$(date '+%F_%H:%M:%S')

#Define location for logs as a variable $logloc
logloc="/Users/$accountName/GAMWork/logs/$NOW.log"

(
    #Sets path of GAM
    GAM3=/Users/$accountName/bin/gamadv-xtd3/gam
    echo "GAM3=$GAM3"
    echo

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

    echo "Please enter all groups separated by commas and without any spaces"
    echo "eg ./addGroups group@domain.com,people@domain.com,test@domain.com"
    echo

    while true; do
        read -p "Enter email that should be added to the groups: " username
        validate_email $username && break
        echo "Invalid email address. Please try again."
    done
    echo

    read -p "Enter the group membership type, either Member, Manager, or Owner: " role

    oIFS="$IFS"
    IFS=,
    set -- $1
    IFS="$oIFS"
    for i in "$@"; do
        $GAM3 update group $i add $role user $username || error_exit "Failed to add user to group: $i"
        echo "Added $username to $i"
    done
    echo "Added to: $# group(s)!"

) 2>&1 | tee -a $logloc
