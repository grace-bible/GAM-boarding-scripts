#!/bin/bash

read -p "What is the email of the user you want to offboard?" email


while true; do
    read -p "Are you sure the email of the user is ($email) Yes or No?" yn
    case $yn in
       [Yy]* ) echo "GAM OFFBOARDING STARTED"; break;;
       [Nn]* ) exit;;
         * ) echo "Please answer yes or no.";;
    esac
done

#Path to your GAM setup
GAM="$HOME/bin/gam/gam"

for user in $email
    do $GAM info user $email
       $GAM user $email signout
       $GAM update user $email ou (ENTER YOUR OU)
       $GAM user $email delete group
       $GAM update user $email password random
       $GAM update user $email gal off
       $GAM user $email deprovision
       $GAM user $email update backupcodes
       $GAM info user $email

done

echo "$email has been offboarded from Google"
