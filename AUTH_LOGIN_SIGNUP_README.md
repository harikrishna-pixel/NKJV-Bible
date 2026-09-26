# Login and Sign Up — how this NLT app works

Checked from the current code. This is **what the app does today**, not a port guide.

Host (AuthHub):

```text
https://bibleoffice.com/authhub/API/public/
```

This app’s AuthHub `app_id` (hardcoded in `BibleInfo.appID`):

```text
e8b91815-ed0a-11ef-b28e-fa163e8c011b
```

Content-Type on all three calls:

```text
application/x-www-form-urlencoded
```

---

## 1. Client ID and Client Secret — hardcoded or not?

**Live Login / Sign Up do not hardcode `client_id` or `client_secret`.**

They are read from `.env` at runtime (`flutter_dotenv`).

| Item | Where | Hardcoded? |
|------|--------|------------|
| `.env` key for client id | `AssetsConstants.clientid` = `'CLIENTID'` | **No** — this is only the **key name** |
| `.env` key for client secret | `AssetsConstants.clientSecret` = `'CLIENTSECRET'` | **No** — this is only the **key name** |
| Actual values | `.env` → `CLIENTID` / `CLIENTSECRET` | **Not in Dart.** Loaded in `main.dart` via `dotenv.load(fileName: ".env")` |
| `app_id` | `lib/view/screens/dashboard/constants.dart` → `BibleInfo.appID` | **Yes** — hardcoded |
| Old leftovers | `lib/controller/api_service.dart` lines ~72–74 | **Commented out. Not used.** |

Used by:

- `getTempToken()` in `lib/controller/api_service.dart`
- `Temptokenapi.gettokenaccess()` in `lib/core/api/auth/temp_token.api.dart`

```dart
'client_id': dotenv.env[AssetsConstants.clientid] ?? '',
'client_secret': dotenv.env[AssetsConstants.clientSecret] ?? '',
'app_id': BibleInfo.appID,
```

If `.env` is missing those keys, the app sends **empty strings**. Temp-token then fails.

Do **not** copy `.env` secrets into another app. Each app needs its own `CLIENTID`, `CLIENTSECRET`, and `app_id`.

---

## 2. Order of calls

Every Login and every Sign Up does this:

1. **POST `/api/temp-token`** (no user Bearer) → `data.temp_access_token`
2. **POST `/api/register`** or **POST `/api/login`** with  
   `Authorization: Bearer <temp_access_token>`
3. If `status` is true, cache session keys (below)
4. UI: Sign Up may show own-referral dialog; Login goes to Home (or pops if opened from Prayer Wall)

Forgot-password (`send-otp` / `verify-otp` / `reset-pwd`) is **not** part of this Login/Sign Up path.

---

## 3. APIs

| # | Method | Full URL | When |
|---|--------|----------|------|
| 1 | POST | `https://bibleoffice.com/authhub/API/public/api/temp-token` | Before register and before login |
| 2 | POST | `https://bibleoffice.com/authhub/API/public/api/register` | Sign Up |
| 3 | POST | `https://bibleoffice.com/authhub/API/public/api/login` | Login (and Sign Up fallback if own `referral_code` was empty) |

Constants: `lib/constant/app_api_constant.dart` and `Api` in `lib/controller/api_service.dart`.

---

## 4. Temp token

### Request

```http
POST https://bibleoffice.com/authhub/API/public/api/temp-token
Content-Type: application/x-www-form-urlencoded
```

Body (form):

```text
client_id=<from .env CLIENTID>
client_secret=<from .env CLIENTSECRET>
app_id=e8b91815-ed0a-11ef-b28e-fa163e8c011b
```

No `Authorization` header.

### Response (what the app reads)

The app only uses:

```text
data.temp_access_token
```

Typical shape:

```json
{
  "status": true,
  "status_code": 200,
  "data": {
    "temp_access_token": "<jwt>"
  }
}
```

If `temp_access_token` is missing, the app throws `Failed to get temp token`.

---

## 5. Sign Up

### UI

- Screen: `lib/view/screens/authenitcation/view/signup_screen.dart`
- Bloc: `SignupBloc.createAccount()` → `registerUser(...)`
- Fields: name, email, password, confirm password, optional **Referral Code (optional)**
- Email must pass `AppEmailValidator` (Gmail only)
- User must accept Terms / Privacy

### Request

```http
POST https://bibleoffice.com/authhub/API/public/api/register
Content-Type: application/x-www-form-urlencoded
Authorization: Bearer <temp_access_token>
```

Body (form) — always:

```text
name=<typed name>
email=<typed email>
password=<typed password>
password_confirmation=<same password>
device_type=iOS
app_id=e8b91815-ed0a-11ef-b28e-fa163e8c011b
interested_vc_tags=<selected_categories from prefs, as a string>
```

`device_type` is `iOS` or `Android`.

If the referral field is **not empty**, the app also sends the **friend’s** code on **both** keys:

```text
referred_by=<typed invite code>
referral_code=<typed invite code>
```

The user’s **own** share code is **not** sent. It comes back on `user.referral_code`.

### Response (success — `status` must be true)

The app treats success as `data['status']` truthy. It then reads:

| Path | Used for |
|------|----------|
| `data.user.email` | cache `user` |
| `data.user.user_id` | cache `userid` |
| `data.user.name` | cache `name` |
| `data.token` | cache `authtoken` |
| `data.user.referral_code` (or `referralCode`) | cache `referral_code` (own share code) |
| `data.user.referred_by` / `referredBy` | invite accepted only if this matches the typed code |

Typical shape:

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

`status_code` 200 alone is **not** enough. The app requires `status` true.

### Fail

```json
{
  "status": false,
  "message": "<error text>"
}
```

The app throws `data['message']` (or `Failed to register`).

### After a successful register (app-side)

1. Cache `user`, `userid`, `name`, `authtoken`, own `referral_code`.
2. Cache `referred_by` **only if** AuthHub `referred_by` matches the typed invite (or a profile snapshot confirms it).
3. Toast: `Account Created Successfully`.
4. If an invite was typed **and** the app thinks it was applied: `WalletService.addCredits(100)`, then `updateReferralRewardClaimed(100)`, toast `You received 100 free coins!`.
5. If an invite was typed **and** the app does **not** see `referred_by`: toast `Code is invalid`. **Account is still created.**
6. Show **Your Referral Code** dialog (own code).
7. Go to Home, or pop back if Sign Up was opened from Prayer Wall.

**Known gap:** AuthHub often returns `status: true` with **empty** `referred_by` even for a valid invite. The app then shows **Code is invalid** and does not add the 100 coins.

---

## 6. Login

### UI

- Screen: `lib/view/screens/authenitcation/view/login_screen.dart`
- Bloc: `LoginBloc.login()` → `loginUser(email, password)`
- Fields: email, password
- Email must pass `AppEmailValidator` (Gmail only)
- Password min length 6
- **Does not** send a referral code on normal Login
- **Does not** open the Enter Referral sheet after Login

### Request (normal Login)

```http
POST https://bibleoffice.com/authhub/API/public/api/login
Content-Type: application/x-www-form-urlencoded
Authorization: Bearer <temp_access_token>
```

Body (form):

```text
email=<typed email>
password=<typed password>
app_id=e8b91815-ed0a-11ef-b28e-fa163e8c011b
device_type=iOS
```

`device_type` is `iOS` or `Android`.

### Extra: Login used to apply a referral (Account sheet, not the Login screen)

`applyReferralViaLogin` / `loginUser(..., referralCode:)` also send:

```text
referred_by=<typed friend code>
```

Normal Login from the Login screen does **not** send this.

### Response (success — `status` must be true)

Same envelope as register. The app caches the same session keys, then builds `UserModel` from `data.user` + `data.token`.

Fields parsed into `UserModel`:

```text
user_id
name
email
address
phoneNumber
photoURL
app_id
referral_code
referred_by
referral_count
referral_reward_claimed
wallet_balance
```

Typical shape:

```json
{
  "status": true,
  "status_code": 200,
  "message": "Logged in successfully",
  "data": {
    "token": "<user authtoken>",
    "user": {
      "user_id": "...",
      "name": "...",
      "email": "...",
      "referral_code": "ABC123",
      "referred_by": "",
      "referral_count": 0,
      "referral_reward_claimed": 0,
      "wallet_balance": 0
    }
  }
}
```

### Fail

```json
{
  "status": false,
  "message": "<error text>"
}
```

The app throws `data['message']` (or `Failed to login`).

### After a successful login (app-side)

1. Cache `user`, `userid`, `name`, `authtoken`, own `referral_code`.
2. Library backup upload (background).
3. Prayer Wall identity resolve.
4. If `referral_count` grew: add `delta * 100` local coins for User 1 (watermark `local_referral_count_credited_<userId>`).
5. Sync local wallet from `wallet_balance` if present.
6. Toast welcome and go to Home (or pop if Login was opened from Prayer Wall).

---

## 7. What the app stores after Login / Sign Up

| Cache key | Value |
|-----------|--------|
| `user` | email |
| `userid` | AuthHub `user_id` |
| `name` | display name |
| `authtoken` | `data.token` (user token — not the temp token) |
| `referral_code` | this user’s own share code |
| `referred_by` | friend’s code, only if the app confirmed apply |

Later profile-update calls send:

```text
Authorization: Bearer <authtoken>
```

---

## 8. Source files

| File | Role |
|------|------|
| `lib/constant/app_api_constant.dart` | Host + paths |
| `lib/controller/api_service.dart` | `getTempToken`, `registerUser`, `loginUser` |
| `lib/core/api/auth/temp_token.api.dart` | Alternate temp-token helper |
| `lib/view/constants/assets_constants.dart` | `.env` key names `CLIENTID` / `CLIENTSECRET` |
| `lib/view/screens/dashboard/constants.dart` | Hardcoded `appID` |
| `lib/view/screens/authenitcation/view/login_screen.dart` | Login UI |
| `lib/view/screens/authenitcation/view/signup_screen.dart` | Sign Up UI |
| `lib/view/screens/authenitcation/bloc/login_bloc.dart` | Calls `loginUser` |
| `lib/view/screens/authenitcation/bloc/signup_bloc.dart` | Calls `registerUser` |
| `lib/view/screens/profile/model/user_model.dart` | Login user JSON |
| `.env` | Real `CLIENTID` / `CLIENTSECRET` (not in Dart) |
| `lib/main.dart` | `dotenv.load(fileName: ".env")` |

---

## 9. Short answers

| Question | Answer |
|----------|--------|
| Are `client_id` / `client_secret` hardcoded? | **No** (live). They come from `.env`. |
| Is `app_id` hardcoded? | **Yes.** |
| What does Sign Up send for a referral? | Friend’s code on both `referred_by` and `referral_code`. |
| What does Login send for a referral? | Nothing on the Login screen. Account-apply login sends `referred_by` only. |
| Success rule | `status` true. Not `status_code` 200 alone. |
