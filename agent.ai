# STRICT CHANGE CONTROL RULES

## Purpose

These rules apply to every task in this project.

You MUST change ONLY what the user explicitly requests.

The user's requested task is the highest priority.

---

## 1. ONLY CHANGE THE REQUESTED TASK

- Make the smallest possible change.
- Do not refactor unrelated code.
- Do not optimize unrelated code.
- Do not clean up unrelated code.
- Do not redesign existing functionality.
- Do not add improvements that were not requested.
- Do not modify code "for consistency" unless required by the task.

---

## 2. PROTECTED FILES AND SYSTEMS

The following are PROTECTED by default.

DO NOT modify them unless the user explicitly gives permission:

### Database
- Database files
- Database schema
- Tables
- SQL queries unrelated to the task
- Database initialization
- Database migration
- Database restore/recovery
- Database encryption
- SQLCipher
- Database keys
- Local database storage

### Environment / Security
- `.env`
- Environment variables
- API keys
- Encryption keys
- Secrets
- Credentials
- Certificates

### Dependencies
- `pubspec.yaml`
- `pubspec.lock`
- `Podfile`
- `Podfile.lock`
- Package versions
- CocoaPods dependencies
- Flutter SDK configuration

### iOS
- Xcode project configuration
- Bundle identifier
- Signing
- Provisioning
- Entitlements
- Build settings
- Info.plist
- App capabilities
- iOS native configuration

### Android
- Gradle configuration
- AndroidManifest
- Signing configuration
- Application ID
- Build configuration

### Backend / API
- API endpoints
- API request/response models
- Authentication
- User identity
- Backend integration
- Network configuration

### Payments
- RevenueCat
- In-App Purchases
- Subscriptions
- Paywall
- Purchase restoration
- Payment validation
- Coins
- AI credits

### User Data
- User accounts
- Library data
- Bookmarks
- Highlights
- Underlines
- Notes
- Reading history
- Local user preferences

### Other Important Features
- Prayer Wall
- Login/Register
- Authentication
- Navigation logic
- App initialization
- Splash logic

Unless the user specifically asks to change one of these, LEAVE IT COMPLETELY UNTOUCHED.

---

## 3. UI TASKS

If the user asks for a UI change:

- Change ONLY the requested UI.
- Do not change backend logic.
- Do not change database logic.
- Do not change API logic.
- Do not change authentication.
- Do not change payments.
- Do not change subscriptions.
- Do not change navigation unless explicitly requested.
- Do not change another screen.
- Do not change unrelated widgets.

---

## 4. BEFORE EDITING

First inspect the existing code.

Identify:

1. The exact file that needs to change.
2. The exact widget/function/class that needs to change.
3. Whether the requested task can be completed without touching protected areas.

Prefer the smallest change possible.

---

## 5. STOP CONDITION

If completing the requested task requires changing any protected system, STOP.

Do NOT make the change automatically.

Ask the user for explicit permission first.

Example:

> This task requires changing `lib/controller/dpProvider.dart`, which contains database initialization logic. Do you want me to modify it?

---

## 6. DO NOT MAKE EXTRA CHANGES

Never say:

- "I also improved..."
- "I cleaned up..."
- "I refactored..."
- "I optimized..."
- "I fixed another issue..."
- "I updated related code..."

unless the user explicitly requested those changes.

Unrequested changes are NOT allowed.

---

## 7. DO NOT DELETE EXISTING CODE

Do not delete existing code unless:

- The user explicitly asks for removal, OR
- Removing it is absolutely required to complete the requested task.

Never delete database migration, restore, authentication, payment, or security code as part of an unrelated task.

---

## 8. DO NOT CREATE UNNECESSARY FILES

Do not create:

- New classes
- New services
- New dependencies
- New files
- New abstractions

unless they are actually required for the requested task.

---

## 9. PRESERVE EXISTING FUNCTIONALITY

Everything outside the requested task must continue working exactly as before.

Do not change existing behavior unnecessarily.

---

## 10. VALIDATION

After making the change:

- Check for Dart/analyzer errors.
- Check for obvious compile errors.
- Verify that only necessary files were modified.
- Do not modify additional files just to remove unrelated warnings.

---

## 11. FINAL RESPONSE

After completing the task, report:

### Files changed
List only the files actually modified.

### Changes made
Briefly explain exactly what was changed.

### Protected areas
Confirm that protected areas were not modified.

### Unrelated changes
Confirm:

> No unrelated logic or files were changed.

If a protected file was modified with permission, clearly state why it was required.

---

# ABSOLUTE RULE

CHANGE ONLY WHAT THE USER ASKED FOR.

IF YOU ARE NOT SURE WHETHER SOMETHING SHOULD BE CHANGED:

STOP AND ASK THE USER.

DO NOT GUESS.
DO NOT IMPROVE.
DO NOT REFACTOR.
DO NOT TOUCH PROTECTED SYSTEMS.
