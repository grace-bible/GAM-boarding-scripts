#!/bin/bash

gam3 create user $onboard_user firstname $onboard_first_name lastname $onboard_last_name org New\ users notify $recovery_email,$onboard_manager subject "[ACTION REQUIRED] Activate your #email# email" password "${TEMP_PASS}" notifypassword "${TEMP_PASS}" changepasswordatnextlogin
gam3 update user $onboard_user Employment_History.Start_dates multivalued $NOW
gam3 update user $onboard_user organization description "$department" costcenter "$campus" title "$job_title" primary
gam3 user $onboard_user signature file $sigFile replace NAME "$onboard_first_name $onboard_last_name" replace TITLE "$job_title"
gam3 user $onboard_user show signature format
gam3 info user $onboard_user
