# Google Workspace User Provisioning and Deprovisioning Scripts

This bash script automates the process of onboarding new users in Google Workspace. It uses the [Google Apps Manager (GAMADV-XTD3)](https://github.com/taers232c/GAMADV-XTD3) command-line tool to interact with Google Workspace APIs.

## Features

- **User Input Interaction:** The script prompts the administrator to input essential details for the new user, such as first name, last name, recovery email, HR email, etc.

- **User Creation:** Creates a new user in Google Workspace with a randomly generated password. Sends notifications to the recovery email and HR email. The user is required to change the password at the next login.

- **Organizational Unit (OU) Assignment:** Sets the organizational unit for the new user to "New users."

- **Group Memberships:** Adds the new user to campus-specific staff email groups, calendar, and drive based on their reporting campus.

- **Org Directory Information Update:** Updates organizational directory information for the new user, including employee type, reporting campus, department, and job title.

- **Email Signature Setup:** Configures the email signature for the new user using a predefined template.

- **Admin Verification:** Validates the admin's email address and downloads the new hire tracker sheet from Google Drive.

- **Logs and Audit:** Logs the provisioning process and uploads logs to an IT subcommittee Team Drive folder for audit and reference.

## Prerequisites

1. Install [GAMADV-XTD3)](https://github.com/taers232c/GAMADV-XTD3) and set it up with the required permissions.

2. Make sure to customize paths and file locations according to your environment.

## Usage

1. Run the script in the terminal: `./provision_user.sh`

2. Follow the prompts to input the necessary information for the new user.

3. The script will create the user, update group memberships, set up the email signature, and log the process.

4. Verify the admin's email address for additional tasks.

5. Logs are saved locally and uploaded to a specified Team Drive folder.

## Notes

- Ensure that sensitive information, such as passwords, is handled securely.

- Customize the script according to your organization's specific needs.

## License

This script is licensed under the [MIT License](LICENSE).
