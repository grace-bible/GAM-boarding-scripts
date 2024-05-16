#!/bin/bash

bash <(curl -s -S -L https://gam-shortn.appspot.com/gam-install) -l

# Get the current date in the YYYY-MM-DD format
date_prefix=$(date '+%Y-%m-%d %H%M')

# Define the output file names with the date prefix
orgs_file="${date_prefix} gam orgs.csv"
users_file="${date_prefix} gam users.csv"
groups_file="${date_prefix} gam groups.csv"
aliases_file="${date_prefix} gam aliases.csv"
roles_file="${date_prefix} gam roles.csv"
admins_file="${date_prefix} gam admins.csv"
calendars_file="${date_prefix} gam calendars.csv"
resources_file="${date_prefix} gam resources.csv"
teamdrives_file="${date_prefix} gam teamdrives.csv"

# Execute the commands and redirect the output to the respective files
gam3 print orgs >"$orgs_file"
gam3 print users allfields >"$users_file"
gam3 print groups allfields >"$groups_file"
gam3 print aliases >"$aliases_file"
gam3 print roles >"$roles_file"
gam3 print admins >"$admins_file"
gam3 all users print calendars >"$calendars_file"
gam3 print resources allfields >"$resources_file"
gam3 all users teamdrives >"$teamdrives_file"
gam3 print users query "isEnrolledIn2sv=False isSuspended=False" >"${date_prefix} MFA.csv"

# Print the 5 Google Apps reports: a list of all of the hosted accounts that exist in your domain, the number of active and idle accounts, the amount of disk space occupied, etc.
gam3 report accounts >"${date_prefix} report accounts.csv"
gam3 report activity >"${date_prefix} report activity.csv"
gam3 report disk_space >"${date_prefix} report disk_space.csv"
gam3 report email_clients >"${date_prefix} report email_clients.csv"
gam3 report summary >"${date_prefix} report summary.csv"
