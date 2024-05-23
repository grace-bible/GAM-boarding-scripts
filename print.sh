#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Update GAM
bash <(curl -s -S -L https://gam-shortn.appspot.com/gam-install) -l

# Update GAMADV-XTD3
bash <(curl -s -S -L https://raw.githubusercontent.com/taers232c/GAMADV-XTD3/master/src/gam-install.sh) -l

source "$(dirname "$0")/config.env"

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
${GAM3} print orgs >"$orgs_file"
${GAM3} print users allfields >"$users_file"
${GAM3} print groups allfields >"$groups_file"
${GAM3} print aliases >"$aliases_file"
${GAM3} print adminroles privileges >"$roles_file"
${GAM3} print admins >"$admins_file"
${GAM3} all users print calendars >"$calendars_file"
${GAM3} print resources allfields >"$resources_file"
${GAM3} print teamdriveacls oneitemperrow >"$teamdrives_file"
${GAM3} print users query "isEnrolledIn2sv=False isSuspended=False" >"${date_prefix} MFA.csv"

# Print the 5 Google Apps reports: a list of all of the hosted accounts that exist in your domain, the number of active and idle accounts, the amount of disk space occupied, etc.
#${GAM3} report accounts >"${date_prefix} report accounts.csv"
#${GAM3} report activity >"${date_prefix} report activity.csv"
#${GAM3} report disk_space >"${date_prefix} report disk_space.csv"
#${GAM3} report email_clients >"${date_prefix} report email_clients.csv"
#${GAM3} report summary >"${date_prefix} report summary.csv"
