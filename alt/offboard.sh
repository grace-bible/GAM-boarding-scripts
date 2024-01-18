#!/bin/sh

echo "Input the email address of the user to be deprovisioned from Google Workspace, followed by [ENTER]"
read termed_email_address

echo "Input the email address of the receiving Manager, followed by [ENTER]"
read receiving_email_address

~/bin/gam/gam update user $termed_email_address password random gal off
~/bin/gam/gam user $termed_email_address deprovision
~/bin/gam/gam user $termed_email_address add forwardingaddress $receiving_email_address
~/bin/gam/gam user $termed_email_address forward on $receiving_email_address delete
~/bin/gam/gam user $termed_email_address transfer drive $receiving_email_address
~/bin/gam/gam calendar $termed_email_address add owner $receiving_email_address

echo "G Suite deprovisioning for ${termed_email_address} complete"
