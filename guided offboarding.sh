#!/bin/bash

#Setting log location and how it captures error
accountName=$(whoami)

GAM3files=/Users/$accountName/GAMWork
logDir=/Users/$accountName/GAMWork/logs

#Setting up directory structure
if [ ! -d "$GAM3files" ]; then
    echo "Setting up GAMWork directory.."
    mkdir $GAM3files
    echo
else
    echo
fi

if [ ! -d "$logDir" ]; then
    echo "Setting up Logs directory"
    mkdir $logDir
    echo
else
    echo
fi

#Define today's date and time as a variable $NOW
NOW=$(date '+%F_%H:%M:%S')

#Define location for logs as a variable $logloc
logloc="/Users/$accountName/GAMWork/logs/$NOW.log"
(
    #Sets path of GAM, please make sure to change this path to reflect your GAM path. Use 'gam version' to find your path.
    GAM3=/Users/$accountName/bin/gamadv-xtd3/gam

    # these two variables are used for error handling purposes
    invalidUsernameString="Does not exist"
    validUsernameString="User"

    echo
    echo "Enter the full email address of a user that you are terminating."

    while [ "$verifyUsername" != *"$invalidUsernameString"* ]; do
        #prompting for input and saving it into a variable.
        read -p "Email address: " username
        echo
        echo "Validating email address..."
        echo
        #Verifies username by using the command below and saves the output into a variable , which is then compared to a string to handle error
        verifyUsername=$($GAM3 whatis $username noinfo 2>&1)

        if [[ "$verifyUsername" != *"$validUsernameString"* ]]; then
            echo "Invalid email address, try again."
        fi

        if [[ "$verifyUsername" == *"$validUsernameString"* ]]; then
            #Wiping user's calendar
            read -p "Would you like to ERASE user's calendar ? (Y/N) " ans

            case $ans in
            y | Y)
                echo
                echo Clearing up calendar events of $username
                $GAM3 calendar $username wipe
                echo
                ;;
            n | N)
                echo
                echo "Alrighty then, it's been skipped."
                echo
                ;;
            esac

            #Transferring calendar data and releasing resources
            read -p "Would you rather TRANSFER calendar data to a manager? (Y/N) " ans
            case $ans in
            y | Y)
                while [ "$verifyManager" != *"$invalidUsernameString"* ]; do
                    echo
                    read -p "Enter Full email address of the manager: " manager
                    echo
                    echo "Validating email address..."
                    verifyManager=$($GAM3 whatis $manager noinfo 2>&1)

                    if [[ "$verifyManager" != *"$validUsernameString"* ]]; then
                        echo "Invalid email address, try again."
                    fi

                    if [[ "$verifyManager" == *"$validUsernameString"* ]]; then
                        echo
                        echo "Initiating transfer of calendar data from $username to $manager"
                        $GAM3 create datatransfer $username calendar $manager release_resources
                        break
                    fi
                done
                ;;
            n | N)
                echo
                echo "Alrighty then, it's been skipped."
                echo
                ;;
            esac

            #setting the terminated user to suspended state
            echo
            echo Suspending user $username
            $GAM3 update user $username suspended on
            echo $username is suspended

            #removing the user from all of their groups
            echo
            echo removing $username from all the groups they belong to
            $GAM3 user $username delete groups

            #Moving user to the terminated OU
            echo
            echo Moving $username to Terminated Users OU
            $GAM3 update ou /Staff/Inactive move user $username

            # deprovisioning all of their SSO tokens
            echo
            echo "Deprovisioning $username SSO Tokens"
            $GAM3 user $username deprovision
            echo

            #removing gmail account related data from user's mobile devices.
            echo "Gathering mobile devices for $username"
            IFS=$'\n'
            mobile_devices=($($GAM3 print mobile query $username | grep -v resourceId | awk -F"," '{print $1}'))
            unset IFS
            for mobileid in ${mobile_devices[@]}; do
                $GAM3 update mobile $mobileid action account_wipe && echo "Removing $mobileid from $username"
            done

            #Transferring docs to the manager
            read -p "Would you like to transfer Google Drive data to a manager? (Y/N) " ans

            case $ans in
            y | Y)
                while [ "$verifyManager" != *"$invalidUsernameString"* ]; do
                    echo
                    read -p "Enter Full email address of the recipient: " manager
                    echo
                    echo "Validating email address..."
                    verifyManager=$($GAM3 whatis $manager noinfo 2>&1)

                    if [[ "$verifyManager" != *"$validUsernameString"* ]]; then
                        echo "Invalid email address, try again."
                    fi

                    if [[ "$verifyManager" == *"$validUsernameString"* ]]; then
                        echo
                        echo "Initiating Drive transfer from $username to $manager"
                        $GAM3 create transfer $username drive $manager private
                        break
                    fi
                done
                ;;
            n | N)
                echo
                echo "Alrighty then, it's been skipped."
                ;;
            esac

            # Collecting admin email address for logs and uploading to IT Team drive
            echo
            echo "To upload the log to IT subcommittee Shared Drive, enter your admin email address ?"
            while [ "$verifyAdmin" != *"$invalidUsernameString"* ]; do
                read -p "Admin Email address: " adminname
                echo
                echo "Validating email address..."
                verifyAdmin=$($GAM3 whatis $adminname noinfo 2>&1)
                if [[ "$verifyAdmin" != *"$validUsernameString"* ]]; then
                    echo "Invalid Email address, try again."
                fi

                if [[ "$verifyAdmin" == *"$validUsernameString"* ]]; then
                    echo
                    echo "Initiating Upload of log"
                    echo
                    echo "$username is deprovisioned from G-Suite on $NOW by $adminname"
                    echo
                    #Make sure to change the drive folder id to match your preferred folder
                    $GAM3 user $adminname add drivefile localfile $logloc teamdriveparentid 1DAyRjit9zBmQlN3QOBzTbxf1FlN2bFX7
                    echo
                    echo "Locally, you can find the log at: "
                    echo $logloc
                    echo
                    break
                fi
            done
            break
        fi
    done

) 2>&1 | tee -a $logloc
