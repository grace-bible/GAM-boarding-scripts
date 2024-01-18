#!/bin/sh

echo "Input the email address of the user to be deprovisioned from Google Workspace, followed by [ENTER]"
read termed_email_address

echo "Input the email address of the receiving Manager, followed by [ENTER]"
read receiving_email_address

#Path to your GAM setup
GAM=/Users/$accountName/bin/gam/gam
GAM3=/Users/$accountName/bin/gamadv-xtd3/gam

$GAM info user $termed_email_address
$GAM user $termed_email_address signout
$GAM update user $termed_email_address ou (ENTER YOUR OU)
$GAM user $termed_email_address delete group
$GAM update user $termed_email_address password random
$GAM update user $termed_email_address gal off
$GAM user $termed_email_address deprovision
$GAM update user $termed_email_address password random gal off
$GAM user $termed_email_address update backupcodes
$GAM user $termed_email_address add forwardingaddress $receiving_email_address
$GAM user $termed_email_address forward on $receiving_email_address delete
$GAM user $termed_email_address transfer drive $receiving_email_address
$GAM info user $termed_email_address

echo "Google Workspace deprovisioning for ${termed_email_address} is complete"
