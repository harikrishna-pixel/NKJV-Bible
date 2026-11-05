# biblebookapp

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Sign in / Login

**Screen:** `lib/view/screens/authenitcation/view/login_screen.dart`

Open from Menu / My Account, Prayer Wall, and other features that require an account.

- **Email** and **password** (password at least 6 characters).
- **Forgot Password?** opens the reset screen.
- **Sign Up** opens the registration screen.
- After a successful login the app goes to **Reading (Home)**.
- Login from Prayer Wall stays on the Wall (it does not replace Home).
- If the email is not verified, the app opens **Mail Verification**.
- The referral-code sheet is **not** shown on login. Enter a friend’s code later in **My Account**.

Cache after login: `userid`, `authtoken`, `name`, `user` (email). Cloud library backup can run about 60 seconds after a successful sign-in (see below).

## Sign up

**Screen:** `lib/view/screens/authenitcation/view/signup_screen.dart`

Create an account to back up and restore the Bible journey across devices.

| Field | Required |
|--------|----------|
| Name | Yes |
| Email | Yes (valid email) |
| Password | Yes (at least 8 characters) |
| Confirm Password | Yes (must match) |
| Referral Code | Optional |
| Terms & Privacy checkbox | Yes |

- Link at the bottom: **Sign In** (existing account).
- Optional referral code can also be entered after sign-up from **My Account**.

## Profile (My Account)

**Screen:** `lib/view/screens/profile/view/profile_screen.dart`  
**Edit:** `lib/view/screens/profile/view/edit_profile_screen.dart`

My Account is for a signed-in user.

- **Edit Profile** — name, photo, country, and related account details. Delete account is on this screen.
- **Wallet** — credits, Premium, Restore purchases (same Wallet entry as Settings / Menu).
- **Prayer Profile** — opens Prayer Wall profile.
- **Library** — bookmarks, highlights, notes, quotes, wallpapers (counts; tap to open My Library).
- **Referral** — own code (copy / share) and **Enter Referral Code** if none has been applied yet.
- **Logout** — clears the session on this device.

## Referral code

**Apply a code (friend’s code)**

- Optional field on **Sign Up**.
- After login: **My Account → Enter Referral Code**.
- You cannot apply your own code.
- A code can be applied only once per account. If one is already used, the app shows “Referral code already applied”.

**Share your code**

- Shown on **My Account** when the account has a referral code.
- Copy or share. The share text includes the app store link and the code.
- When a friend signs up with that code, **both** accounts get **100 free credits**.

**Files**

- Sign-up / post-login sheet: `lib/view/screens/authenitcation/view/widget/referral_code_bottom_sheet.dart`
- My Account section + share/copy: `lib/view/screens/authenitcation/view/widget/own_referral_code_dialog.dart`
- Cached key: `referral_code`

## Library cloud backup

My Library data (bookmarks, highlights, underlines, notes, wallpaper/quote bookmarks, and calendar entries) can be backed up to the server when the user is signed in. Bible reader/home content is not included. Backups are encrypted (`.enc`) locally; cloud uploads send a `.zip` containing that file.

Implementation: `lib/core/library_backup_upload_service.dart`, triggered from `lib/main.dart` and after login in `lib/controller/api_service.dart` / `lib/core/notifiers/auth/auth.notifier.dart`.

### Manual backup (My Library)

- **EXPORT (Manual)** — Saves `Geneva Bible_Backup.enc` on the device and also uploads to the cloud (when logged in).
- **IMPORT (Manual)** — Restores from a local `.enc` file.
- **IMPORT FROM CLOUD** — Downloads the latest server backup and restores it (same decrypt/import path as manual).

### Automatic cloud backup

Automatic uploads require a logged-in user (`userid` and `authtoken` in cache). If the user is not signed in, no automatic cloud backup runs.

| Trigger | When it runs |
|--------|----------------|
| **After login** | About **60 seconds** after a successful sign-in or registration (does not block navigation). Keep the app open for at least a minute so this upload can finish. |
| **Daily (2 AM rule)** | On the **first app open after 2:00 AM** local time each calendar day, about **60 seconds** after launch (deferred so splash/Home DB loading is not blocked). Also checked about **30 seconds** after the app returns to the foreground (`resumed`), if the daily backup has not already run that day. |

**Important:** This is **not** a background job at exactly 2:00 AM while the app is closed. If the user does not open the app, **no** scheduled backup runs at midnight or 2 AM. The server keeps the last successful upload until a newer one replaces it.

### Daily backup — what time to open the app?

- Open the app **any time from 2:00 AM onward** on that day (e.g. 2:00 AM, 8:00 AM, evening).
- Stay logged in; wait roughly **one minute** on the first screen after open so the deferred upload can complete.
- Opening **before 2:00 AM** does not count for that day’s scheduled backup; open again **after 2:00 AM**, or rely on the post-login backup (which can run at any time of day).

### What is stored on the server?

Each successful upload replaces the user’s cloud backup for that app/account. Use **IMPORT FROM CLOUD** on a new device or after reinstall to restore the latest stored backup.
