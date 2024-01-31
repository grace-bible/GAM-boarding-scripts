#!/bin/bash

################################################################################################
#										VARIABLES											   #
################################################################################################

subjectFR=""

subjectEN=""

messageFR=""

messageEN=""

if [[ "$3" == "EN" ]]; then
    message="$messageEN"
    subject="$subjectEN"
elif [[ "$3" == "FR" ]]; then
    message="$messageFR"
    subject="$subjectFR"
else
    # If $3 is neither "EN" nor "FR," you can handle the default case here.
    # For example, set default values or display an error message.
    echo "Unsupported language: $3"
    exit 1
fi

loggedInUser=$(echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ { print $3 }')

currentDate=$(date +%F)

currentDate1y=$(date -v+1y "+%Y-%m-%d")

################################################################################################
#									VARIABLES END											   #
################################################################################################

################################################################################################
#										RECOVERY										   	   #
################################################################################################

/Users/$loggedInUser/bin/gamadv-xtd3/gam update user $1 recoveryemail ""
/Users/$loggedInUser/bin/gamadv-xtd3/gam update user $1 recoveryphone ""
/Users/$loggedInUser/bin/gamadv-xtd3/gam user $1 turnoff2sv

################################################################################################
#										FORWARDING											   #
################################################################################################

/Users/$loggedInUser/bin/gamadv-xtd3/gam user $1 add forwardingaddress $2
/Users/$loggedInUser/bin/gamadv-xtd3/gam user $1 forward on keep $2

################################################################################################
#										AUTO-REPLY											   #
################################################################################################

/Users/$loggedInUser/bin/gamadv-xtd3/gam user $1 vacation on subject "$subject" message "$message" startdate "$currentDate" enddate "$currentDate1y"

################################################################################################
#										REMOVE GROUPS										   #
################################################################################################

/Users/$loggedInUser/bin/gamadv-xtd3/gam user $1 delete groups

################################################################################################
#										LIST DRIVES										       #
################################################################################################

/Users/$loggedInUser/bin/gamadv-xtd3/gam redirect csv ./TeamDrives.csv print teamdrives fields id,name
/Users/$loggedInUser/bin/gamadv-xtd3/gam redirect csv ./TeamDriveACLs.csv multiprocess csv ./TeamDrives.csv gam print drivefileacls "~id" fields id,emailaddress,role,type,deleted oneitemperrow

################################################################################################
#										REMOVE DRIVES										   #
################################################################################################

/opt/homebrew/Cellar/csvkit/1.1.1/bin/csvcut -c 2,5,6 ./TeamDriveACLs.csv | /opt/homebrew/Cellar/csvkit/1.1.1/bin/csvgrep -c permission.emailAddress -m $1 >DriveUserAccess.csv
/Users/$loggedInUser/bin/gamadv-xtd3/gam csv ./DriveUserAccess.csv gam user $4 delete drivefileacl "~id" "~permission.emailAddress"

################################################################################################
#										SIGNIN COOKIES										   #
################################################################################################

/Users/$loggedInUser/bin/gamadv-xtd3/gam user $1 signout

################################################################################################
#										TRANSFER DRIVE OWNERSHIP							   #
################################################################################################

/Users/$loggedInUser/bin/gamadv-xtd3/gam user $1 transfer drive $2 keepuser

################################################################################################
#										DELETE CSVS										   	   #
################################################################################################

rm TeamDrives.csv TeamDriveACLs.csv DriveUserAccess.csv
