#!/bin/sh

accountName=$(whoami)

#Define today's date and time as a variable $NOW
NOW=$(date '+%F_%H:%M:%S')

#Define location for logs as a variable $logloc
logloc=/Users/$accountName/GAMWork/logs

(
    #Sets path of GAM
    GAM3=/Users/$accountName/bin/gamadv-xtd3/gam
    echo "GAM3=$GAM3"
    echo
    echo

    echo "Input the email address of the user to be deprovisioned from Google Workspace, followed by [ENTER]"
    read offboard_email_address
    echo
    echo

    echo "Input the email address of the receiving Manager, followed by [ENTER]"
    read receiving_email_address
    echo
    echo

    $GAM3 info user $offboard_email_address

    #Reset password
    echo "Generating random password..."
    $GAM3 update user $offboard_email_address password random gal off
    echo

    #Deprovision
    echo "Deprovisioning..."
    $GAM3 user $offboard_email_address deprovision
    echo

    #Forward emails
    echo "Forwarding emails..."
    $GAM3 user $offboard_email_address add forwardingaddress $receiving_email_address
    echo

    #Configure forwarding to delete
    echo "Configuring email forwarding to delete..."
    $GAM3 user $offboard_email_address forward on $receiving_email_address delete
    echo

    #Transfer files
    echo "Transferring Drive files..."
    $GAM3 user $offboard_email_address transfer drive $receiving_email_address
    echo

    #Transfer calendar
    echo "Transferring Calendar..."
    $GAM3 calendar $offboard_email_address add owner $receiving_email_address
    echo

    #Disable GAL directory
    echo "Disabling GAL..."
    $GAM3 update user $offboard_email_address gal false
    echo

    echo "Google Workspace deprovisioning for ${offboard_email_address} complete"

) 2>&1 | tee -a $logloc
