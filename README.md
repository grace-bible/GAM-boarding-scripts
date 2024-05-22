# GAM Google Workspace User Management Scripts

This repository offers Bash scripts that simplify user management in Google Workspace using GAMADV-XTD3 command-line tool, automating tasks like onboarding, offboarding, and updates for consistent and efficient administration.

## Prerequisites

1. **GAMADV-XTD3**: Ensure that GAMADV-XTD3 is installed and configured on your machine.
2. **Bash**: The scripts are designed to run in a Bash shell environment.

## Features

- **Onboarding Script (`onboard.sh`)**:

  - Creates new user accounts.
  - Sets up email signatures and group memberships.
  - Adds employment details and calendar events.

- **Offboarding Script (`offboard.sh`)**:

  - Resets passwords and clears recovery options.
  - Transfers Drive and Calendar data.
  - Configures email forwarding and auto-replies.
  - Removes users from groups and hides from the GAL.

- **Reporting Script (`print.sh`)**:
  - Generates various reports on users, groups, aliases, admins, calendars, and resources.

## Setup

1. **Clone the Repository**:

   ```bash
   git clone <repository_url>
   cd <repository_directory>
   ```

2. **Configure `config.env`**:

   - Create a `config.env` file with necessary environment variables such as `LOG_DIR`, `GAM_CMD`, `SIG_FILE`, `CC_HR`, `BDAY_CAL`, and `GAM_LAST_UPDATE`.

   ### Sample `config.env`

   ```bash
   # Directory for logs
   LOG_DIR=/path/to/log/directory

   # Path to GAM executable
   GAM3=/path/to/gamadv-xtd3/gam

   # Path to email signature file
   SIG_FILE=/path/to/signature.txt

   # HR email for notifications
   CC_HR=hr@yourdomain.com

   # Birthday calendar ID
   BDAY_CAL=your_calendar_id@group.calendar.google.com

   # Last update date for GAM
   GAM_LAST_UPDATE=2024-05-22

   # Update interval in days
   UPDATE_INTERVAL_DAYS=7
   ```

3. **Install Dependencies**:
   Ensure that all required tools and dependencies are installed and updated. This includes GAMADV-XTD3, which can be installed using the following commands:
   ```bash
   bash <(curl -s -S -L https://gam-shortn.appspot.com/gam-install) -l
   bash <(curl -s -S -L https://raw.githubusercontent.com/taers232c/GAMADV-XTD3/master/src/gam-install.sh) -l
   ```

## Usage

### Onboarding Script

**Syntax**:

```bash
./onboard.sh [-h] [<onboard_first_name> <onboard_last_name> <recovery_email> <onboard_user> <manager_email_address> <campus> <job_title> (<birthday>)]
```

**Options**:

- `-h`: Print the help message.

**Arguments**:

1. `onboard_first_name`: User's first name.
2. `onboard_last_name`: User's last name.
3. `onboard_user`: New domain email for the user.
4. `manager_email_address`: User's manager email.
5. `recovery_email`: Personal email for the onboarding user.
6. `campus`: Assigned campus (AND, SW, CRK, MT, SYS).
7. `job_title`: User's official job title (optional).
8. `birthday`: User's birthday (YYYY-MM-DD) for the company birthday calendar (optional).

### Offboarding Script

**Syntax**:

```bash
./offboard.sh [-h] [<offboard_user> (<receiving_user>)]
```

**Options**:

- `-h`: Print the help message.

**Arguments**:

1. `offboard_user`: User email for the offboarding user.
2. `receiving_user`: User email for the receiving user of any transfers.

### Reporting Script

**Syntax**:

```bash
./print.sh
```

### Detailed Steps for Onboarding

1. **Create User**:

   - Sets a temporary password and notifies the user and HR.
   - Sets the employment start date and adds the user's birthday to the company calendar.

2. **Set Signature**:

   - Configures the user's email signature based on a template.

3. **Add Groups**:
   - Adds the user to specified groups with appropriate permissions.

### Detailed Steps for Offboarding

1. **Get Info**:

   - Logs the user's information for audit purposes.

2. **Reset Password and Recovery Options**:

   - Generates a random password and clears recovery options.

3. **Deprovision**:

   - Disables services and clears access tokens.

4. **Transfer Data**:

   - Transfers the user's Drive and Calendar data to another user.

5. **Set Auto-Reply and Forwarding**:

   - Configures an autoreply message and forwards incoming emails.

6. **Suspend User**:
   - Suspends the user account after all other steps are complete.

## Notes

- Both onboarding and offboarding scripts include interactive whiptail menus for selecting and executing tasks.
- Ensure that `config.env` is correctly configured with all required paths and settings.
- Review and test the scripts in a controlled environment before deploying them in production.
- Both scripts will regularly check for updates to GAM and GAMADV-XTD3 to ensure compatibility with the latest Google Workspace APIs.
- Feel free to submit issues and pull requests to improve functionality and compatibility.

## License

This project is licensed under the MIT License.
