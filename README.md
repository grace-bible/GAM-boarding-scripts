# Google Workspace User Provisioning and Deprovisioning Scripts

This bash script automates the process of onboarding new users in Google Workspace. It uses the [Google Apps Manager (GAMADV-XTD3)](https://github.com/taers232c/GAMADV-XTD3) command-line tool to interact with Google Workspace APIs.

> [!CAUTION]
> Ensure that sensitive information, such as passwords, is handled securely. Be careful publishing real passwords (even temporary ones) in a repo, and only disable `changepasswordatnextlogin` in [onboard.sh](/onboard.sh) if you know what you're doing.

## Features

- **Interactive shell input:** The script prompts the administrator to input essential details for a new user, such as first name, last name, recovery email, manager, etc.

- **Log executed functions for audit:** Logs the provisioning process and uploads logs to a specified folder for audit and reference.

### Onboarding features

- **Create new users:** Creates a new user in Google Workspace with a randomly generated password. Sends notifications to the recovery email and manager email. The user is required to change the password at the next login. Sets the organizational unit (OU) for the new user to `New users` until MFA can be configured at the first IT onboard meeting.

- **Updates org directory information:** Updates organizational directory information for the new user, including employee type, campus, department, and job title.

- **Setup email signature:** Configures the email signature for the new user using [a predefined template](/dependencies/signature.txt).

- **Add to security and mailing Groups:** Adds the new user to campus-specific staff email groups, role-based permission groups, team-based functional groups, calendars, and drives based on the campus and department(s).

### Offboarding features

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
> **Both the [onboarding script](/onboard.sh) and the [offboarding script](/offboard.sh) will run with either CLI arguments _or_ with user prompted input.** If an unexpected number of arguments are received, the script will proceed with the guided boarding process. _Remember to customize the scripts according to your organization's specific needs!_

1. Run the script in the terminal:

   - `bash ./onboard.sh` runs the [guided onboarding process](/onboard.sh)
   - `bash ./offboard.sh` runs the [guided offboarding process](/offboard.sh)

2. Follow the prompts to input the necessary information for the new user.

3. The script will create the user, update group memberships, set up the email signature, and log the process.

4. Logs are saved locally and uploaded to a specified Team Drive folder.

# IT boarding checklists

## Detailed onboarding checklist

> [!NOTE]
> The [onboarding script](/onboard.sh) expects exactly eight (8) arguments at entry in the following order: `onboard_first_name`, `onboard_last_name`, `onboard_user`, `recovery_email`, `campus`, `job_title`, `manager_email_address`, and `birthday`. Any more (or fewer) arguments will fail over to a guided entry, which will prompt for each variable sequentially.

### Collect employee personal info

- [ ] Legal name
- [ ] Preferred nickname
- [ ] Personal email (for password delivery)
- [ ] Personal phone (for multifactor authentication)
- [ ] Birthday (for calendar)

### Collect employee professional info

- [ ] Campus
- [ ] Office location
- [ ] Expected work hours
- [ ] Job title
- [ ] Manager email
- [ ] Start date
- [ ] Employment type (status)

### Onboard the operational environment

#### Groups for security and email:

- [ ] Department(s)
- [ ] Role(s)
  - Fellows: Directors, First Year, Second Year, Third Year
  - Operations, Administrators, Supervisors, etc.
  - Ministry Leads, Ministers, MOD, etc.
- [ ] Campus, office, or working group(s)
- [ ] Team(s)
  - Vision, Strategy, Management, Operations, etc.
  - Hubs, Facilities, IT, etc.

#### Other

- [ ] Provision door access codes, keys, security cameras
- [ ] Provision secondary software: Notion, Canva, Adobe, etc.

### Deploy appropriate equipment

#### Mac

- [ ] `$1,999.00` 14-inch MacBook Pro: Apple M3 chip with 8‑core CPU and 10‑core GPU, 16GB RAM 512GB SSD - Space Gray
- [ ] `$237.00` AppleCare+ for 14‑inch MacBook Pro (M3)
- [ ] `$80.00` MX ANYWHERE 3S
- [ ] `$110.00` MX KEYS S
- [ ] `$350.00` LG Ultrawide monitor 34WR50QC-B
- [ ] `$70.00` Apple MultiPort Adapter

#### PC

- [ ] `$2,000.00` Dell Latitude 7440 14 inch I7-1355U 16GB 1DIMM 512GB W1114IN
- [ ] `$80.00` MX ANYWHERE 3S
- [ ] `$110.00` MX KEYS S
- [ ] `$280.00` ViewSonic 27 Inch 1440p IPS Monitor with 65W USB
- [ ] `$70.00` Dell Thunderbolt Dock - WD22TB4

## Detailed offboarding checklist

> [!NOTE]
> The [offboarding script](/offboard.sh) expects exactly two (2) arguments at entry in the following order: `offboard_user` and `receiving_user`. Any more (or fewer) arguments will fail over to a guided entry, which will prompt for each variable sequentially.

### Collect employee personal info

- [ ] Personal email and/or phone (to coordinate asset recovery)

### Collect employee professional info

- [ ] Office location (for asset recovery)
- [ ] End date

#### Other

- [ ] [Inbox transfer](https://support.google.com/a/answer/6351475): manager, successor, or none
- [ ] [Email forwarding](https://support.google.com/a/answer/4524505): manager, successor, or none
- [ ] [Drive transfer](https://support.google.com/drive/answer/2494892): manager, successor, Shared Drive, or none
- [ ] [Calendar transfer](https://support.google.com/calendar/answer/78739): manager, successor, or none
- [ ] Deprovision door access codes, keys, security cameras
- [ ] [Deprovision](https://support.google.com/a/answer/6329207) software permissions:
  - Google Workspace
  - Active Directory
  - CCB (Groups, Process Queues, Forms, Departments, etc.)
  - Pushpay, ShelbyNext
  - Avigilon, enteliWEB
  - Adobe, Canva, Meta (Facebook, Instagram, etc.), MailChimp, Flickr
  - Slack
  - Planning Center, Resi, Bluebolt, Multitracks, Soundtrack Your Brand, Bitwarden
  - Notion, Tally, GitHub, n8n, Meraki
- [ ] Suspend or delete the user account[^1]

> [!WARNING]
> Make _sure_ you need to _delete_ a user before doing so!

### Reclaim issued assets

- [ ] Computer, keyboard, mouse, monitor

[^1]: By suspending a user at offboarding instead of deleting them, we avoid the irreversible action [until we can confidently proceed](https://support.google.com/a/answer/9048836).

## License

This script is licensed under the [MIT License](LICENSE).

Though almost entirely different (to the point that it's not a branch), this project was largelyl inspired by [deepanudaiyar's G-Suite repo](https://github.com/deepanudaiyar/G-Suite)
