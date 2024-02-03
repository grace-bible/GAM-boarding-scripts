#!/bin/bash

accountName=$(whoami)

#Define today's date and time as a variable $NOW
NOW=$(date '+%F')

#Make sure to change the path of your signature file below
sigFile=/Users/$accountName/repos/GAM-boarding-scripts/dependencies/signature.txt

#Define location for logs as a variable $logloc
logDir=/Users/joshmckenna/Library/CloudStorage/GoogleDrive-joshmckenna@grace-bible.org/Shared\ drives/IT\ subcommittee/_ARCHIVE/gam

if [ -d "$logDir" ]; then
    echo "Logging to Google Drive File Stream via joshmckenna@grace-bible.org"
    logloc=$logDir/$NOW.log
    echo
elif [ ! -d "/Users/$accountName/GAMWork/logs/" ]; then
    echo "Setting up Logs directory"
    mkdir $logDir
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
    echo

    echo "Input the FIRST NAME of the new user to be provisioned in Google Workspace, followed by [ENTER]"
    read onboard_first_name
    echo
    echo

    echo "Input the LAST NAME of the new user to be provisioned in Google Workspace, followed by [ENTER]"
    read onboard_last_name
    echo
    echo

    echo "Input the PERSONAL RECOVERY EMAIL of the new user to be provisioned in Google Workspace, followed by [ENTER]"
    read recovery_email
    echo
    echo

    echo "Input the HUMAN RESOURCES EMAIL to be notify of the newly created user, followed by [ENTER]"
    read hr_email
    echo
    echo

    echo "Input the WORK EMAIL of the new user to be provisioned in Google Workspace, followed by [ENTER]"
    read onboard_email_address
    echo
    echo

    echo "Input the email address of the new user's Manager, followed by [ENTER]"
    read manager_email_address
    echo
    echo

    #Create new user, generate password, notify recovery email and hiring manager, set OU to "New users"
    echo
    echo "Creating new user..."
    $GAM3 create user $onboard_email_address firstname $onboard_first_name lastname $onboard_last_name org New\ users notify $recovery_email,$hr_email subject "[ACTION REQUIRED] Activate your #email# email" password "{{EXAMPLE_PASS_HERE}}" notifypassword "{{EMAILED_PASS_HINT}}" changepasswordatnextlogin
    echo
    echo

    #Update org directory info
    echo "What type of employee is this?"
    echo " Admin"
    echo " Staff"
    echo " Fellow"
    echo " Non-staff (MOU, seconded, lay leader, etc.)"
    read type_of_employee
    echo
    echo

    echo "What is the employee's reporting campus?"
    echo " AND"
    echo " SW"
    echo " CRK"
    echo " MT"
    echo " SYS"
    echo " KK"
    read cost_center
    echo
    echo
    #Add user to campus groups
    case $cost_center in
    AND)
        echo "Adding user to Anderson campus staff email Groups, Calendar, and Drive."
        $GAM3 update group and-staff@grace-bible.org add member $onboard_email_address
        ;;
    SW)
        echo "Adding user to Southwood campus staff email Groups, Calendar, and Drive."
        $GAM3 update group sw-staff@grace-bible.org add member $onboard_email_address
        ;;
    CRK)
        echo "Adding user to Creekside campus staff email Groups, Calendar, and Drive."
        $GAM3 update group crk-staff@grace-bible.org add member $onboard_email_address
        ;;
    MT)
        echo "Adding user to Midtown campus staff email Groups, Calendar, and Drive."
        $GAM3 update group mt-staff@grace-bible.org add member $onboard_email_address
        ;;
    SYS)
        echo "Adding user to System staff email Groups, Calendar, and Drive."
        $GAM3 update group sys-staff@grace-bible.org add member $onboard_email_address
        ;;
    KK)
        #echo "Adding user to Kingdom Kids staff email Groups, Calendar, and Drive."
        #$GAM3 update group  add member $onboard_email_address
        echo "Kingdom Kids groups and resources haven't been clearly defined yet."
        ;;
    *)
        echo
        echo "Please enter a valid option."
        echo
        ;;
    esac

    echo "What is (are) the employee's department(s)?"
    echo " Grace56"
    echo " Youth"
    echo " Youth Impact"
    echo " College"
    echo " Young Adults"
    echo " Adult"
    echo " Global Outreach"
    echo " Mobilization"
    read department
    echo
    echo

    echo "What is the employee's job title?"
    read job_title
    echo
    echo

    echo "Updating employee org info"
    $GAM3 update user $onboard_email_address relation manager $manager_email_address organization description "$type_of_employee" costcenter "$cost_center" department "$department" title "$job_title" primary
    echo
    echo

    #Setting signature
    echo "Setting up Signature..."
    $GAM3 user $onboard_email_address signature file $sigFile replace NAME "$onboard_first_name $onboard_last_name" replace TITLE "$job_title"
    echo
    echo
    echo "Here's the current signature of the user:"
    $GAM3 user $onboard_email_address show signature format
    echo
    echo

    #Define error handling for admin verification
    invalidUsernameString="Does not exist"
    validUsernameString="User"

    #Verifies admin email address & downloads the new hire tracker sheet from google drive
    echo "To complete onboarding and upload logs, verify your admin email address."
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
            echo "Administrator verified"
            echo
            # Please make sure to change the id below to match your excel or google sheet file
            # $GAM3 user $adminName get drivefile id {{INSERT GOOGLE DRIVE FILE ID HERE}} format microsoft targetfolder /Users/$accountName/GAMWork targetname newHireTracker.xlsx overwrite true
            break
        fi
    done

    #Uploading logs to IT subcommittee Team Drive folder for audit and reference
    echo "Initiating saving of logs"
    echo
    echo "User is provisioned in Google Workspace by $adminName at $NOW"
    #Make sure to change the folder id of your g-drive below
    #$GAM3 user $adminName add drivefile localfile $logloc teamdriveparentid 1Gb2n_u9KD5AMQ3EunO51pUE44SKTnoxm
    echo
    echo "Locally, you can find the log at: "
    echo $logloc
    echo

    $GAM3 info user $onboard_email_address

    echo "Google Workspace provisioning for $onboard_email_address complete"
    echo
    echo "Emailed credentials to $recovery_email and $hr_email"
    echo

    #redirect stdout/stderr to a file
) 2>&1 | tee -a "$logloc"
