## Google Workspace User Management Scripts

This repository contains Bash scripts for automating the onboarding and offboarding of users in Google Workspace using the GAMADV-XTD3 command-line tool. The scripts are designed to streamline these processes and ensure consistency across different environments.

### Prerequisites

1. **GAMADV-XTD3**: Ensure that GAMADV-XTD3 is installed and configured on your machine.
2. **Bash**: The scripts are designed to run in a Bash shell environment.

### Setup

1. **Clone the Repository**:

   ```bash
   git clone <repository_url>
   cd <repository_directory>
   ```

2. **Create and Configure `config.env`**:
   Create a `config.env` file in the root directory of the repository with the following variables. This file will be sourced by the scripts to configure necessary paths and settings.

   **Example `config.env`**:

   ```env
   # Directory for storing logs
   LOG_DIR="../_ARCHIVE/gam"

   # Path to the GAMADV-XTD3 command
   GAM_CMD="../bin/gamadv-xtd3/gam"

   # Path to the signature template file
   SIG_FILE="dependencies/signature.txt"

   # Email addresses for notifications
   CC_HR="hr@company.com"

   # Calendar ID for the staff birthday calendar
   BDAY_CAL="somegroup@group.calendar.google.com"
   ```

3. **Install Dependencies**:
   Ensure that all required tools and dependencies are installed and updated. This includes GAMADV-XTD3, which can be installed using the following commands:
   ```bash
   bash <(curl -s -S -L https://gam-shortn.appspot.com/gam-install) -l
   bash <(curl -s -S -L https://raw.githubusercontent.com/taers232c/GAMADV-XTD3/master/src/gam-install.sh) -l
   ```

### Usage

#### Onboarding Script

The `onboard.sh` script automates the process of onboarding new users in Google Workspace.

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

**Example**:

```bash
./onboard.sh John Doe john.doe@company.com manager@company.com john.doe@example.com AND "Software Engineer" 1990-01-01
```

**Functionality**:

- The script can be run with or without arguments. If arguments are not provided, it will prompt the user for input.
- It performs tasks such as creating the user, setting up the email signature, and adding the user to groups based on the provided inputs.

#### Offboarding Script

The `offboard.sh` script automates the process of offboarding users in Google Workspace.

**Syntax**:

```bash
./offboard.sh [-h] [<offboard_user> <receiving_user>]
```

**Options**:

- `-h`: Print the help message.

**Arguments**:

1. `offboard_user`: User email for the offboarding user.
2. `receiving_user`: User email for the receiving user of any transfers.

**Example**:

```bash
./offboard.sh jane.doe@company.com admin@company.com
```

**Functionality**:

- The script can be run with or without arguments. If arguments are not provided, it will prompt the user for input.
- It performs tasks such as unsuspending the user account, resetting passwords, transferring drive and calendar data, and setting email forwarding.

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

### Notes

- Ensure that `config.env` is correctly configured with all required paths and settings.
- Review and test the scripts in a controlled environment before deploying them in production.
- Regularly update GAMADV-XTD3 to ensure compatibility with the latest Google Workspace APIs.
