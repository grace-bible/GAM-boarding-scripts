# IT boarding checklists

## Onboarding

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

## Offboarding

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
