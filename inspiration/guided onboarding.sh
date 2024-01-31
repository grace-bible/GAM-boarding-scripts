#!/bin/bash

accountName=$(whoami)
newUserCsv=./dependencies/newUser.csv
groupCsv=./dependencies/groupsToAdd.csv
#Make sure to change the path of your signature file below
sigFile=./dependencies/signature.html
GAM3files=/Users/$accountName/GAMWork
logDir=/Users/$accountName/GAMWork/logs

#Setting up directory structure
if [ ! -d "$GAM3files" ]; then
    echo "Setting up GAMfiles directory.."
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
    #Sets path of GAM
    GAM3=/Users/$accountName/bin/gamadv-xtd3/gam

    # these two variables are used for error handling purposes
    invalidUsernameString="Does not exist"
    validUsernameString="User"

    #Verifies admin email address & downloads the new hire tracker sheet from google drive
    echo "To download the latest New Hire Tracker file, Enter your admin email address."
    while [ "$verifyAdmin" != *"$invalidUsernameString"* ]; do
        read -p "Admin Email address: " adminName
        echo
        echo "Validating email address..."
        verifyAdmin=$($GAM3 whatis $adminName noinfo 2>&1)
        if [[ "$verifyAdmin" != *"$validUsernameString"* ]]; then
            echo "Invalid Email address, try again."
        fi

        if [[ "$verifyAdmin" == *"$validUsernameString"* ]]; then
            echo
            echo "Downloading File.."
            echo
            # Please make sure to change the id below to match your excel or google sheet file
            $GAM3 user $adminName get drivefile id {{INSERT GOOGLE DRIVE FILE ID HERE}} format microsoft targetfolder /Users/$accountName/GAMWork targetname newHireTracker.xlsx overwrite true
            break
        fi
    done

    # Confirm new hire info from excel sheet and save the details into a csv file and previewing data
    echo
    echo "Review and/or edit the $newUserCsv file with your data and save it."
    echo
    echo "Use the following column headers in this exact order for $newUserCsv: "
    echo "fullName, jobTitle, managerEmail, dept, startDate, personalEmail, first, last, email"
    echo
    # Making sure that the end user have verified new hire info in the newUser.csv file
    echo "Please make sure that you have a *LICENSE* available and verify the *newUser.csv* before proceeding further."
    echo
    echo "Once verified, enter Y to Proceed :"
    while :; do
        read opt
        case $opt in
        y | Y)
            echo
            echo "Creating user"
            #Generate random password
            pwd=$(openssl rand -base64 12)

            #create user
            $GAM3 csv $newUserCsv gam create user \~email firstname \~first lastname \~last password $pwd changepasswordatnextlogin True

            #fill in profile details
            echo
            echo "Updating profile details.."
            $GAM3 csv $newUserCsv gam update user \~email relation manager \~managerEmail organization title \~jobTitle department \~dept

            #Moving to a specific OU
            echo
            read -p "Would you like to move this user to any specific OU other than default ? (Y/N) " ans
            case $ans in
            y | Y)
                while :; do
                    echo
                    echo "Alright, Choose one of the following OU:"
                    echo "1. Staff/Permanent"
                    echo "2. Staff/Occasional"
                    echo "3. Staff/Fellows"
                    echo "4. Staff/Kingdom\ Kids"
                    read opt
                    case $opt in
                    1)
                        echo "Moving user to Staff/Permanent"
                        $GAM3 csv $newUserCsv gam update org Staff/Permanent move user \~email
                        break
                        ;;
                    2)
                        echo "Moving user to Staff/Occasional"
                        $GAM3 csv $newUserCsv gam update org Staff/Occasional move user \~email
                        break
                        ;;
                    3)
                        echo "Moving user to Staff/Fellows"
                        $GAM3 csv $newUserCsv gam update org Staff/Fellows move user \~email
                        break
                        ;;
                    4)
                        echo "Moving user to Staff/Kingdom\ Kids"
                        $GAM3 csv $newUserCsv gam update org Staff/Kingdom\ Kids move user \~email
                        break
                        ;;
                    *)
                        echo
                        echo "Please enter a valid option."
                        echo
                        ;;
                    esac
                done
                ;;
            n | N)
                echo
                echo "Alrighty then..."
                ;;
            esac

            #Running Python script to collect info for adding groups to user
            echo
            while :; do
                read -p "Would you like to add groups to this user ? (Y/N) " ans
                case $ans in
                y | Y)
                    echo
                    echo "Review and/or edit the $groupCsv file with your data and save it."
                    echo
                    echo "Use the following column headers in this exact order for $groupCsv: "
                    echo "groupName, memberName"
                    echo
                    echo "Please verify the groupsToAdd.csv before proceeding further. Once verified, press Y to Proceed: "
                    while :; do
                        read opt
                        case $opt in
                        y | Y)
                            echo
                            $GAM3 csv $groupCsv gam update groups \~groupName add member \~memberName
                            echo
                            break
                            ;;
                        *)
                            echo
                            echo "Please enter a valid option."
                            echo
                            ;;
                        esac
                    done
                    break
                    ;;
                n | N)
                    echo
                    echo "Alrighty then..."
                    break
                    ;;
                *)
                    echo
                    echo "Enter a valid option"
                    echo
                    ;;
                esac
            done
            break
            ;;
        *)
            echo
            echo "Please enter a valid option."
            echo
            ;;
        esac
    done

    #Setting signature

    echo "Setting up Signature..."
    echo
    $GAM3 csv $newUserCsv gam user \~email signature file $sigFile replace fullName field:name.fullName replace title field:organization.title replace phonenumber field:phone.value.type.work
    echo
    echo "Here's the current signature of the user"
    echo
    $GAM3 csv $newUserCsv gam user \~email show signature format
    echo

    #Uploading logs to I.T team G-drive folder for audit purpose and reference.
    echo "Initiating upload of log.."
    echo
    echo "User is provisioned in G by $adminName at $NOW"
    #Make sure to change the folder id of your g-drive below
    $GAM3 user $adminName add drivefile localfile $logLoc teamdriveparentid 1n8580FUK8-x1N_8UUxj5DvTnmNexlQem
    echo
    echo "Locally, you can find the log at: "
    echo $logLoc
    echo
    #Running bye.py to give few key details that could help in next steps
    echo "Onboarding complete, here are some key details for takeout:"
    echo
    echo "{username} is now provisioned on G-Suite"
    echo
    echo "Email address: {email}"
    echo
    echo "Start date: {startDate}"
    echo
    echo "Email credentials to: {personalEmail}"
    echo
    echo "Password:               $pwd"
    echo
    echo

)
#redirect stdout/stderr to a file
2>&1 | tee -a $logLoc
