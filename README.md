# Google Workspace User Provisioning and Deprovisioning Scripts

This bash script automates the process of onboarding new users in Google Workspace. It uses the [Google Apps Manager (GAMADV-XTD3)](https://github.com/taers232c/GAMADV-XTD3) command-line tool to interact with Google Workspace APIs.

> [!CAUTION]
> Ensure that sensitive information, such as passwords, is handled securely! Be careful publishing real passwords (even temporary ones) in this repo, and only disable `changepasswordatnextlogin` in [onboard.sh](/onboard.sh) if you know what you're doing.

## Features

- **Interactive shell input:** The script prompts the administrator to input essential details for a new user, such as first name, last name, recovery email, manager, etc.

- **Log executed functions for audit:** Logs the provisioning process and uploads logs to a specified folder for audit and reference.

### Onboarding

- **Create new users:** Creates a new user in Google Workspace with a randomly generated password. Sends notifications to the recovery email and manager email. The user is required to change the password at the next login. Sets the organizational unit (OU) for the new user to `New users` until MFA can be configured at the first IT onboard meeting.

- **Updates org directory information:** Updates organizational directory information for the new user, including employee type, campus, department, and job title.

- **Setup email signature:** Configures the email signature for the new user using [a predefined template](/dependencies/signature.txt).

- **Add to security and mailing Groups:** Adds the new user to campus-specific staff email groups, role-based permission groups, team-based functional groups, calendars, and drives based on the campus and department(s).

### Offboarding

- **Deprovisions user access:** Resets the user password, erases password recovery and multi-factor authentication methods, and deprovisions all `popimap` and `backupcodes`.

- **Sets the end date in the directory:** Sets the employee end date for record as a custom schema.

- **Removes user from directory:** Removes the user from global address list (GAL) directory visibility.

- **Forwards email:** Configures forwarding from the offboarded user to a new receiving user. Sets email autoreply for a year, indicates that the user no longer works for the organization.

- **Transfer drive:** Transfers all `My Drive` files to the specified receiving user.

- **Transfer calendar:** Transfers all user calendar events to the specified receiving user.

- **Removes Group memberships:** Removes the exiting user from all mailing and security Google Groups.

- **Removes Shared Drive memberships:** Removes the exiting user from all directly added Shared Drives.

- **Suspends the user:** Suspends the user account and moves the user to the `Inactive` organizational unit (OU) until formally deleted or archived.

## Prerequisites

1. Install [GAMADV-XTD3)](https://github.com/taers232c/GAMADV-XTD3) and set it up with the required permissions.

2. Make sure to customize paths and file locations according to your environment.

## Usage

> [!TIP]
> Both the [onboarding script](/onboard.sh) and the [offboarding script](/offboard.sh) will run with CLI arguments _or_ with prompted input. If an unexpected number of arguments are received, the script will proceed with the guided boarding process. _Remember to customize the scripts according to your organization's specific needs!_

1. Run the script in the terminal:

   - `bash ./onboard.sh` runs the [guided onboarding process](/onboard.sh)
   - `bash ./offboard.sh` runs the [guided offboarding process](/offboard.sh)

2. Follow the prompts to input the necessary information for the new user.

3. The script will create the user, update group memberships, set up the email signature, and log the process.

4. Logs are saved locally and uploaded to a specified Team Drive folder.

## License

This script is licensed under the [MIT License](LICENSE).

Though almost entirely different (to the point that it's not a branch), this project was largelyl inspired by [deepanudaiyar's G-Suite repo](https://github.com/deepanudaiyar/G-Suite)
