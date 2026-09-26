# Sign Up — full port guide (give this to the other app)

This is how **this NLT Bible app** does Sign Up today: UI rules, APIs, exact bodies, responses, cache, coins, and referral.

**Do not copy this app’s `.env` secrets.** The other app must use **its own** AuthHub values.

---

## 0. Values the other app must have

Get these from AuthHub / the Bible office team for **that** app (not from this repo’s `.env`):

| Value | This NLT app | Other app |
|-------|----------------|-----------|
| AuthHub host | `https://bibleoffice.com/authhub/API/public/` | Same host unless they give you another |
| `app_id` | `e8b91815-ed0a-11ef-b28e-fa163e8c011b` | **Their** app id |
| `client_id` | `.env` key `CLIENTID` | **Their** client id |
| `client_secret` | `.env` key `CLIENTSECRET` | **Their** client secret |
| Bible / app display name | `NLT Bible` | Their name (for share text) |
| iOS bundle / Play package | used only in share download link | Their store links |

This NLT app does **not** hardcode `client_id` / `client_secret`. It reads them from `.env`:

```text
CLIENTID=...
CLIENTSECRET=...
```

`app_id` **is** hardcoded in `BibleInfo.appID`.

If temp-token fields are empty, Sign Up fails before register.

---

## 1. Host and paths

```text
https://bibleoffice.com/authhub/API/public/
```

| Step | Method | Path | Full URL |
|------|--------|------|----------|
| A | POST | `/api/temp-token` | `https://bibleoffice.com/authhub/API/public/api/temp-token` |
| B | POST | `/api/register` | `https://bibleoffice.com/authhub/API/public/api/register` |
| C (optional) | POST | `/api/login` | `https://bibleoffice.com/authhub/API/public/api/login` |
| D (if invite applied) | POST | `/api/profile-update` | `https://bibleoffice.com/authhub/API/public/api/profile-update` |

All bodies: `application/x-www-form-urlencoded`.

---

## 2. Sign Up screen (UI)

File: `lib/view/screens/authenitcation/view/signup_screen.dart`

| Field | Hint | Required | Client rules |
|-------|------|----------|--------------|
| Name | `Name` | Yes | Not empty |
| Email | `Email` | Yes | Valid email **and** domain must be **`gmail.com` only** |
| Password | `Password` | Yes | Min **8** characters |
| Confirm password | `Confirm Password` | Yes | Must match password |
| Referral | `Referral Code (optional)` | No | Trimmed. Empty = skip invite keys |
| Checkbox | Terms & Privacy | Yes | If off: toast `You have to agree our Terms and Condition, and Privacy and Policy.` |

Title: `Welcome!`  
Subtitle: `Sign up to back up and restore your Bible journey anytime, even when switching devices.`

Email reject examples: empty, not an email, `user@yahoo.com`, `user@gmail.cm`, typos.

Confirm password is **client-only**. The API gets `password` and `password_confirmation` (same value).

There is also a `SocialAuthWidget` on the screen. That is **not** the email Sign Up API path below.

---

## 3. Flow (exact order)

```text
1. Validate form + Terms checkbox
2. POST /api/temp-token
3. POST /api/register  (Bearer = temp token)
4. If status true → cache session
5. If invite typed → decide applied / invalid (see §7)
6. Toast Account Created Successfully
7. If invite applied → +100 coins + profile-update claimed
8. Show Your Referral Code dialog (own code from API)
9. Go Home (or pop if opened from Prayer Wall)
```

If register `status` is false, show `message` and **stay** on Sign Up.

---

## 4. API A — temp token

Needed **before** register.

### Headers

```http
POST /api/temp-token
Content-Type: application/x-www-form-urlencoded
```

No `Authorization`.

### Body

```text
client_id=<CLIENTID from .env>
client_secret=<CLIENTSECRET from .env>
app_id=<that app’s app_id>
```

This NLT app sends:

```text
client_id=<dotenv CLIENTID>
client_secret=<dotenv CLIENTSECRET>
app_id=e8b91815-ed0a-11ef-b28e-fa163e8c011b
```

### Response — read this

```text
data.temp_access_token
```

Example:

```json
{
  "status": true,
  "status_code": 200,
  "data": {
    "temp_access_token": "<jwt>"
  }
}
```

If missing → fail: `Failed to get temp token`.

---

## 5. API B — register (the Sign Up call)

### Headers

```http
POST /api/register
Content-Type: application/x-www-form-urlencoded
Authorization: Bearer <temp_access_token>
```

### Body — always

```text
name=<typed name>
email=<typed email>
password=<typed password>
password_confirmation=<same as password>
device_type=iOS
app_id=<that app’s app_id>
interested_vc_tags=<string of selected category prefs>
```

`device_type`: `iOS` or `Android`.

`interested_vc_tags`: this app sends `SharedPreferences` list `selected_categories` as `.toString()` (Dart list string). Can be `[]` if none.

This NLT `app_id`:

```text
e8b91815-ed0a-11ef-b28e-fa163e8c011b
```

### Body — extra if referral field is not empty

Send the **friend’s** code on **both** keys:

```text
referred_by=<typed invite>
referral_code=<typed invite>
```

Do **not** invent the user’s own code. AuthHub returns it as `user.referral_code`.

### Success rule

Use **`status: true`**.  
`status_code: 200` alone is **not** enough (invalid referral can still be 200).

### Success response — fields this app reads

```json
{
  "status": true,
  "status_code": 200,
  "message": "Account Created Successfully",
  "data": {
    "token": "<user authtoken>",
    "user": {
      "user_id": "...",
      "name": "...",
      "email": "...",
      "referral_code": "ABC123",
      "referred_by": "",
      "referral_count": 0,
      "referral_reward_claimed": 0
    }
  }
}
```

| JSON | Save as |
|------|---------|
| `data.user.email` | cache `user` |
| `data.user.user_id` | cache `userid` |
| `data.user.name` | cache `name` |
| `data.token` | cache `authtoken` |
| `data.user.referral_code` or `referralCode` | cache `referral_code` (**own** share code) |
| `data.user.referred_by` or `referredBy` | cache `referred_by` **only if it equals the typed invite** (ignore case) |

Aliases this app also checks: `you_referred_by`, `refered_by`, `referrer_code`.

### Fail response

```json
{
  "status": false,
  "message": "The email has already been taken."
}
```

Show `message`. Do not cache. Do not add coins.

---

## 6. API C — login (Sign Up fallback only)

If register succeeds but own `referral_code` is empty, this app calls login with the **same email/password** to fetch the own code.

### Headers

```http
POST /api/login
Content-Type: application/x-www-form-urlencoded
Authorization: Bearer <new temp_access_token>
```

(Temp token is requested again.)

### Body (this fallback — no invite)

```text
email=<same email>
password=<same password>
app_id=<that app’s app_id>
device_type=iOS
```

### Success — same shape as register

Read `data.token`, `data.user.*` the same way.

Normal Login from the Login screen uses this same API and does **not** send a referral code.

---

## 7. Referral after Sign Up (coins)

**User 2** (person who typed a friend’s code) should get **+100 local coins once**.

This app only pays if it believes AuthHub stored the invite:

1. Cached `referred_by` equals typed code (ignore case), **or**
2. Login/profile `referred_by` equals typed code, **or**
3. New user’s `wallet_balance` ≥ 100

Then:

```text
WalletService.addCredits(100)
POST /api/profile-update   → mark claimed
Toast: You received 100 free coins!
```

If an invite was typed and those checks fail:

```text
Toast: Code is invalid
```

**Account is still created.** Own-code dialog still shows. User still enters the app.

### Known AuthHub gap (you will hit this)

Register often returns `status: true` and **empty** `referred_by` even when the code is valid. Credits often go to **User 1** (the code owner) via `referral_count`, not onto User 2’s `wallet_balance`.

Then this app shows **Code is invalid** and skips User 2’s +100.

**Recommended for the other app:** pay +100 only when `user.referred_by` equals the typed code. If empty, confirm with profile (or treat as not applied). Do not pay just because the field was filled.

---

## 8. API D — mark User 2 claimed

Only after User 2 coins are paid.

### Headers

```http
POST /api/profile-update
Content-Type: application/x-www-form-urlencoded
Authorization: Bearer <authtoken from register — the user token, not temp token>
```

### Body

```text
action=1
key=referral_reward_claimed
value=100
user_id=<cached userid>
app_id=<that app’s app_id>
referred_by=<typed invite>    (only if you have it)
```

`value` is **100** (credits), not `1`.

---

## 9. After success — UI

1. Toast: `Account Created Successfully`
2. Dialog **Your Referral Code** with `user.referral_code`
   - Copy
   - Share:

```text
Grow closer to God with me!

Download the <Bible name> app and use my referral code <CODE> when you sign up to start your own Bible journey.

Download here:
<store link>
```

3. Then Home (or pop back to Prayer Wall / Login if Sign Up was embedded).

This app also:

- Clears Prayer Wall account-scoped local data
- Resolves Prayer Wall identity with email + name  

The other app can skip those if it has no Prayer Wall.

---

## 10. Cache keys to implement

| Key | Value |
|-----|--------|
| `user` | email |
| `userid` | AuthHub `user_id` |
| `name` | name |
| `authtoken` | `data.token` |
| `referral_code` | **own** share code |
| `referred_by` | friend’s code, only if confirmed |

Later logged-in calls use:

```text
Authorization: Bearer <authtoken>
```

---

## 11. User 1 (code owner) — not on the Sign Up screen

When User 2’s invite is accepted, AuthHub increments User 1’s `referral_count`.

When User 1 next logs in, this app:

```text
pending = referral_count - local_referral_count_credited_<userId>
if pending > 0: addCredits(pending * 100)
save watermark = referral_count
```

UI copy: one code is valid for **up to 10 users**.

---

## 12. Toasts / errors

| When | Show |
|------|------|
| Terms not checked | You have to agree our Terms and Condition, and Privacy and Policy. |
| Register `status` true | Account Created Successfully |
| Invite confirmed | You received 100 free coins! |
| Invite typed but not confirmed | Code is invalid |
| Register `status` false | API `message` |
| No network | No Internet Connection |
| Temp token / SSL fail | Something went wrong. Please check your internet connection and try again. |

---

## 13. Checklist for the other app

- [ ] Own AuthHub `app_id`, `client_id`, `client_secret` (not this app’s `.env`)
- [ ] Temp token first; Bearer on register
- [ ] Register always: name, email, password, password_confirmation, device_type, app_id, interested_vc_tags
- [ ] If invite typed: **both** `referred_by` and `referral_code` = friend’s code
- [ ] Success only if `status` is true
- [ ] Cache email, userid, name, authtoken, own `referral_code`
- [ ] Cache `referred_by` only when API value matches typed code
- [ ] User 2 +100 only once, then `referral_reward_claimed=100`
- [ ] Invalid invite: toast, no coins, account still created
- [ ] Show own-code dialog
- [ ] Gmail-only if you copy this app’s email rule
- [ ] Password min 8
- [ ] Do not call Combine, IAP, or Prayer Wall for Sign Up itself

---

## 14. This NLT app — copy-paste values (reference only)

```text
Host:     https://bibleoffice.com/authhub/API/public/
app_id:   e8b91815-ed0a-11ef-b28e-fa163e8c011b
.env:     CLIENTID
.env:     CLIENTSECRET
Name:     NLT Bible
Reward:   100 local coins
```

`client_id` / `client_secret` live values are **only** in `.env`. They are **not** hardcoded in Dart.

---

## 15. Source files (this app)

| File | Role |
|------|------|
| `lib/view/screens/authenitcation/view/signup_screen.dart` | UI + after-register coins / toasts |
| `lib/view/screens/authenitcation/bloc/signup_bloc.dart` | `createAccount()` → `registerUser` |
| `lib/controller/api_service.dart` | `getTempToken`, `registerUser`, `loginUser` |
| `lib/core/api/auth/temp_token.api.dart` | Temp token helper |
| `lib/core/api/auth/profile_update.api.dart` | `referral_reward_claimed` |
| `lib/utils/email_validator.dart` | Gmail-only |
| `lib/view/screens/dashboard/constants.dart` | `appID` |
| `lib/view/constants/assets_constants.dart` | `.env` key names |
| `.env` | Real `CLIENTID` / `CLIENTSECRET` |
| `lib/main.dart` | `dotenv.load(fileName: ".env")` |
