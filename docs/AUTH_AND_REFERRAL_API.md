# AuthHub Login + Referral — Copy-Ready Integration Guide

This document describes the **full login / signup / forgot-password / referral** API contract used by the NKJV Bible app (`AuthHub`), so you can implement the same logic in another app.

**Source of truth in this repo**

| Area | Files |
|------|--------|
| Base URLs | `lib/constant/app_api_constant.dart`, `lib/controller/api_service.dart` |
| Temp token | `lib/core/api/auth/temp_token.api.dart` |
| Register / Login / Forgot | `lib/core/api/auth/register.api.dart`, `lib/controller/api_service.dart` (`registerUser`, `loginUser`) |
| Profile / wallet / referral flags | `lib/core/api/auth/profile_update.api.dart` |
| User fields | `lib/view/screens/profile/model/user_model.dart` |
| Models | `lib/Model/auth/temp_token_model.dart`, `lib/Model/auth/register_model.dart` |

---

## 1. Base URL & credentials

### Base URL

```
https://bibleoffice.com/authhub/API/public/
```

All paths below are relative to that base unless noted as absolute.

### App identity (required on almost every call)

| Field | Meaning | NKJV example value |
|-------|---------|--------------------|
| `app_id` | AuthHub app UUID for **this product** | `03a0762a-ed0b-11ef-b28e-fa163e8c011b` (`BibleInfo.appID`) |
| `client_id` | OAuth client for temp token | from `.env` → `CLIENTID` |
| `client_secret` | OAuth secret for temp token | from `.env` → `CLIENTSECRET` |

**For another app:** register a **new `app_id`** (and usually client credentials) with AuthHub. Do not reuse NKJV’s `app_id` unless AuthHub explicitly allows multi-app sharing.

### Content type & auth headers

Most AuthHub POSTs use:

```http
Content-Type: application/x-www-form-urlencoded
Authorization: Bearer <token>
```

Body is **form fields**, not JSON.

| Call type | Bearer token |
|-----------|--------------|
| Temp token | none |
| Register / Login / Forgot send-OTP | **temp** access token |
| Profile update / delete account / wallet | **user** login token (`data.token`) |
| `POST /api/profile` (read profile) | **temp** token (as this app does) + `user_id` in body |

---

## 2. End-to-end flows (what to call, in order)

### A) Sign Up (recommended place to enter friend’s referral code)

```
1. POST /api/temp-token
2. POST /api/register   ← include referred_by + referral_code here
3. Cache: userid, authtoken, email, name, referral_code, referred_by
4. (optional) POST /api/profile  ← sync referral_count / wallet
```

### B) Login

```
1. POST /api/temp-token
2. POST /api/login
3. Cache same session keys
4. (optional) POST /api/profile
5. (optional) Grant local referrer rewards from referral_count
```

### C) Forgot password

```
1. POST /api/temp-token
2. POST /api/forgot-pwd/send-otp
3. POST /api/forgot-pwd/verify-otp   (no Bearer in this app)
4. POST /api/forgot-pwd/reset-pwd
```

### D) Referral after account already exists (Account / Profile)

AuthHub **rejects** setting referral via normal profile update:

> `"Referral and wallet fields cannot be updated via profile update"`

**Supported path:** pass friend’s code **only on Sign Up** (`/api/register`).

Optional dedicated apply endpoints (`/api/apply-referral-code`, etc.) were probed by this app; they are **not reliably deployed**. Prefer Sign Up only unless backend confirms an Account-apply API.

---

## 3. API reference

### 3.1 Get temporary access token

**Required before** register, login, forgot send-OTP, and (in this app) `/api/profile`.

| | |
|--|--|
| **Method** | `POST` |
| **URL** | `https://bibleoffice.com/authhub/API/public/api/temp-token` |
| **Auth** | none |
| **Headers** | `Content-Type: application/x-www-form-urlencoded` |

**Body**

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `client_id` | string | yes | OAuth client id |
| `client_secret` | string | yes | OAuth secret |
| `app_id` | string | yes | Your AuthHub app id |

**Success response (HTTP 200)**

```json
{
  "status": true,
  "status_code": 200,
  "message": "success",
  "data": {
    "temp_access_token": "<JWT>",
    "expires_in": 900
  }
}
```

**What to use**

- `data.temp_access_token` → `Authorization: Bearer …` on the next call  
- Token typically expires in ~900 seconds — fetch a fresh one per auth action

**cURL**

```bash
curl -X POST 'https://bibleoffice.com/authhub/API/public/api/temp-token' \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d 'client_id=YOUR_CLIENT_ID' \
  -d 'client_secret=YOUR_CLIENT_SECRET' \
  -d 'app_id=YOUR_APP_ID'
```

---

### 3.2 Register (Sign Up) — **apply referral here**

| | |
|--|--|
| **Method** | `POST` |
| **URL** | `…/api/register` |
| **Auth** | `Bearer <temp_access_token>` |
| **Headers** | `Content-Type: application/x-www-form-urlencoded` |

**Body (as used by this app)**

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `name` | string | yes | Display name |
| `email` | string | yes | Unique per app |
| `password` | string | yes | |
| `password_confirmation` | string | yes | Same as password |
| `app_id` | string | yes | |
| `device_type` | string | yes | `"iOS"` or `"Android"` |
| `referred_by` | string | no | **Friend’s invite code** (existing field) |
| `referral_code` | string | no | **Same friend’s invite code** (PDF / Postman field) — send **both** |
| `interested_vc_tags` | string | no | Optional categories list string |
| `email_verify` | string | no | App flag; NKJV uses `"0"` |
| `app_version` | string | no | e.g. `"1.0.0"` |
| `device_version` | string | no | |
| `device_model` | string | no | |
| `device_locale` | string | no | |
| `device_timezone` | string | no | |

**Important:** Friend’s code goes in `referred_by` **and** `referral_code` on **register only**. Do not send the user’s *own* share code here — that is returned by the API after success.

**Success response (HTTP 200)**

```json
{
  "status": true,
  "status_code": 200,
  "message": "Successfully Registered",
  "data": {
    "user": {
      "name": "Jane Doe",
      "email": "jane@example.com",
      "user_id": "<encrypted user id string>",
      "app_id": "<app uuid>",
      "referral_code": "ABCD1234XY",
      "referred_by": "FRIENDCODE1",
      "referral_count": 0,
      "referral_reward_claimed": 0,
      "wallet_balance": 0
    },
    "token": "<user JWT — store as authtoken>"
  }
}
```

> Exact referral/wallet fields may vary by AuthHub version; always parse defensively. This app reads them via `UserModel`.

**Failure (example)**

```json
{
  "status": false,
  "status_code": 400,
  "message": "The email has already been taken.",
  "errors": { }
}
```

**After success — cache these keys (this app)**

| Cache key | Value |
|-----------|--------|
| `user` | email |
| `userid` | `data.user.user_id` |
| `name` | `data.user.name` |
| `authtoken` | `data.token` |
| `referral_code` | user’s **own** share code from response |
| `referred_by` | friend’s code if applied |

**cURL**

```bash
TEMP=... # from temp-token

curl -X POST 'https://bibleoffice.com/authhub/API/public/api/register' \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -H "Authorization: Bearer $TEMP" \
  -d 'name=Jane Doe' \
  -d 'email=jane@example.com' \
  -d 'password=Secret123!' \
  -d 'password_confirmation=Secret123!' \
  -d 'app_id=YOUR_APP_ID' \
  -d 'device_type=iOS' \
  -d 'referred_by=FRIENDCODE1' \
  -d 'referral_code=FRIENDCODE1'
```

---

### 3.3 Login

| | |
|--|--|
| **Method** | `POST` |
| **URL** | `…/api/login` |
| **Auth** | `Bearer <temp_access_token>` |
| **Headers** | `Content-Type: application/x-www-form-urlencoded` |

**Body**

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `email` | string | yes | |
| `password` | string | yes | |
| `app_id` | string | yes | |
| `device_type` | string | yes | `"iOS"` / `"Android"` |
| `referred_by` | string | no | Optional; **not reliable for first-time apply** — use register |
| `referral_code` | string | no | Same as above |
| Device meta | string | no | `app_version`, `device_version`, etc. |

**Success response**

```json
{
  "status": true,
  "status_code": 200,
  "message": "Logged In Successfully",
  "data": {
    "user": {
      "name": "Jane Doe",
      "email": "jane@example.com",
      "user_id": "<encrypted user id>",
      "app_id": "<app uuid>",
      "referral_code": "ABCD1234XY",
      "referred_by": "FRIENDCODE1",
      "referral_count": 2,
      "referral_reward_claimed": 0,
      "referral_reward_credits": 200,
      "total_referred_count": 2,
      "total_claimed_count": 0,
      "wallet_balance": 100
    },
    "token": "<user JWT>"
  }
}
```

**What to use from response**

| Field | Use |
|-------|-----|
| `data.token` | Session Bearer for profile-update / delete |
| `data.user.user_id` | Cached as `userid` |
| `data.user.referral_code` | User’s **own** code to share |
| `data.user.referred_by` | Friend’s code already applied (if any) |
| `data.user.referral_count` | How many people used this user’s code |
| `data.user.wallet_balance` | Server wallet (coins/credits) |

**Failure**

```json
{
  "status": false,
  "message": "Invalid credentials"
}
```

**cURL**

```bash
TEMP=...

curl -X POST 'https://bibleoffice.com/authhub/API/public/api/login' \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -H "Authorization: Bearer $TEMP" \
  -d 'email=jane@example.com' \
  -d 'password=Secret123!' \
  -d 'app_id=YOUR_APP_ID' \
  -d 'device_type=Android'
```

---

### 3.4 Fetch profile (referral sync)

Used after login/register to refresh referral counts / wallet.

| | |
|--|--|
| **Method** | `POST` |
| **URL** | `…/api/profile` |
| **Auth** | `Bearer <temp_access_token>` (this app) |
| **Headers** | `Content-Type: application/x-www-form-urlencoded` |

**Body**

| Field | Required | Notes |
|-------|----------|-------|
| `app_id` | yes | |
| `user_id` | yes | Prefer **login `token`** first; also try cached `user_id` |

**Success** — user object (or `data` map) may include:

- `referral_code`, `referred_by`
- `referral_count`, `total_referred_count`
- `referral_reward_claimed`, `referral_reward_credits`
- `wallet_balance`
- `name`, `email`, `user_id`, `app_id`

Parse both shapes:

1. `data.user.{…}`
2. Flat `data.{referral_count, …}` (no `user` wrapper)

---

### 3.5 Profile update

| | |
|--|--|
| **Method** | `POST` |
| **URL** | `…/api/profile-update` |
| **Auth** | `Bearer <user token>` (`authtoken`) |
| **Headers** | form fields (or multipart for image) |

#### Action `1` — update name / email (or key/value)

**Name/email**

```
action=1
email=...
name=...
user_id=<userid or often the login token>
app_id=...
```

**Key/value style (used for referral flags when backend allows)**

```
action=1
key=referral_reward_claimed
value=1
user_id=...
app_id=...
name=...
referred_by=OPTIONAL
```

**Blocked by backend (do not rely on this for invite apply):**

```
action=1
referred_by=FRIENDCODE
```

Typical error:

```json
{
  "status": false,
  "status_code": 400,
  "message": "Referral and wallet fields cannot be updated via profile update"
}
```

#### Action `3` — profile image (multipart)

| Field | Value |
|-------|--------|
| `action` | `3` |
| `user_id` | user id |
| `app_id` | app id |
| `profile_image` | file (jpg/png/webp, max ~15MB) |
| Header | `Authorization: Bearer <user token>` |

Response includes a profile image URL (`profile_image` / `profile_image_url` / etc.).

#### Action `4` — wallet balance backup

```
action=4
user_id=<prefer login token; fallback cached user_id>
app_id=...
wallet_balance=100
```

Auth: user Bearer token.

---

### 3.6 Forgot password — send OTP

| | |
|--|--|
| **Method** | `POST` |
| **URL** | `…/api/forgot-pwd/send-otp` |
| **Auth** | `Bearer <temp_access_token>` |

**Body**

```
email=user@example.com
app_id=YOUR_APP_ID
```

**Success:** HTTP 2xx + JSON with `status: true` (message may say OTP sent).  
**Failure:** parse `message` / `errors` from body.

---

### 3.7 Forgot password — verify OTP

| | |
|--|--|
| **Method** | `POST` |
| **URL** | `…/api/forgot-pwd/verify-otp` |
| **Auth** | none in this app |

**Body**

```
email=user@example.com
app_id=YOUR_APP_ID
otp=123456
```

Expect a reset `token` in the response body for the next step (field name depends on AuthHub; store whatever token the verify response returns).

---

### 3.8 Forgot password — reset password

| | |
|--|--|
| **Method** | `POST` |
| **URL** | `…/api/forgot-pwd/reset-pwd` |

**Body**

```
email=user@example.com
app_id=YOUR_APP_ID
token=<from verify-otp>
password=NewPass123!
password_confirmation=NewPass123!
```

---

### 3.9 Delete account

| | |
|--|--|
| **Method** | `POST` |
| **URL** | `https://bibleoffice.com/authhub/API/public/api/delete-account` |
| **Auth** | `Bearer <user token>` |

**Body**

```
user_id=<email or user identifier as app sends>
app_id=YOUR_APP_ID
```

(This app currently sends `user_id` = email.)

---

### 3.10 Dedicated apply-referral (optional / often missing)

Paths this app may try:

- `POST …/api/apply-referral-code`
- `POST …/api/referral/apply`
- `POST …/api/referrals/redeem`

**Body variants**

```
referral_code=CODE
app_id=...
user_id=<token or userid>
```

or

```
referred_by=CODE
referral_code=CODE
app_id=...
user_id=...
```

Auth: user Bearer.

**If you get 404 / “page not found”:** endpoint not deployed — use **Sign Up register** only.

---

## 4. Referral product rules (implement the same UX)

| Rule | Detail |
|------|--------|
| When to enter friend’s code | **Sign Up only** (reliable) |
| Own share code | Returned on register/login as `user.referral_code` |
| Rewards (this app UI) | Both sides: **+100** free coins/credits |
| Referrer reward source | Grow `referral_count` on User 1; app grants +100 per new referral locally and may sync `wallet_balance` |
| Cannot use own code | Client check: entered code ≠ own `referral_code` |
| Already applied | Non-empty `referred_by` or `referral_reward_claimed > 0` |
| Account “Enter Referral” | Backend blocks profile update — do not promise Account apply without new API |

### Suggested Sign Up payload for invite

```text
referred_by=<FRIEND_CODE>
referral_code=<FRIEND_CODE>
```

### Fields to show after login

- Share: `referral_code`
- Status: `referred_by` (empty = not invited)
- Stats: `referral_count` / `total_referred_count`
- Wallet: `wallet_balance`

---

## 5. How to detect success vs failure

AuthHub often returns HTTP 200 even when business logic fails. Always check JSON:

```text
status == true  (or 1 / "1" / "true")
AND message does not contain invalid referral
AND errors.referral_code / errors.referred_by empty
```

**Invalid / blocked examples**

| Message (approx.) | Meaning |
|-------------------|---------|
| Invalid referral… | Bad code |
| Referral and wallet fields cannot be updated via profile update | Wrong API path — use register |
| Email already exists | Register conflict |
| Invalid credentials | Login fail |

---

## 6. Minimal implementation checklist (other app)

1. Store `app_id`, `client_id`, `client_secret` securely.
2. Implement `getTempToken()`.
3. Implement `register` with optional `referred_by` + `referral_code`.
4. Implement `login`; cache `token` + `user_id` + referral fields.
5. Implement forgot-password chain (send → verify → reset).
6. Implement `POST /api/profile` for referral/wallet refresh.
7. Implement profile-update action 1 (name) / 3 (photo) / 4 (wallet) as needed.
8. UI: referral **input on Sign Up only**; profile shows **own code** to share.
9. Local cache keys recommended: `authtoken`, `userid`, `user`, `name`, `referral_code`, `referred_by`, `referral_count`, `wallet_balance`.

---

## 7. Pseudocode (copy pattern)

```text
function signUp(name, email, password, friendCode?):
  temp = POST /api/temp-token { client_id, client_secret, app_id }
  body = {
    name, email, password,
    password_confirmation: password,
    app_id, device_type
  }
  if friendCode:
    body.referred_by = friendCode
    body.referral_code = friendCode

  res = POST /api/register
        Authorization: Bearer temp.data.temp_access_token
        body

  if res.status != true: throw res.message

  save(session):
    email, name,
    userid = res.data.user.user_id,
    authtoken = res.data.token,
    referral_code = res.data.user.referral_code,
    referred_by = res.data.user.referred_by || friendCode

  optionally POST /api/profile { app_id, user_id: authtoken or userid }


function login(email, password):
  temp = POST /api/temp-token …
  res = POST /api/login { email, password, app_id, device_type }
  if res.status != true: throw res.message
  save session + referral fields from res.data.user
  sync profile + grant referrer credits if referral_count grew
```

---

## 8. Response field dictionary (user object)

| Field | Type | Meaning |
|-------|------|---------|
| `name` | string | Display name |
| `email` | string | Login email |
| `user_id` | string | Encrypted/opaque AuthHub user id |
| `app_id` | string | App UUID |
| `token` | string | (sibling of `user` under `data`) Session JWT |
| `referral_code` | string | **This user’s** share/invite code |
| `referred_by` | string | Friend’s code used when this user joined |
| `referral_count` | int | People who used this user’s code |
| `total_referred_count` | int | Alternate/total count (if present) |
| `referral_reward_claimed` | int | Claim flag/watermark |
| `referral_reward_credits` | int | Credits attributed to referrals |
| `total_claimed_count` | int | Optional |
| `wallet_balance` | int | Server-side coins/credits |
| `profile_image` | string | Optional URL |

Envelope:

| Field | Meaning |
|-------|---------|
| `status` | boolean success |
| `status_code` | e.g. 200 / 400 |
| `message` | Human message |
| `data` | Payload (`user` + `token`) |
| `errors` | Field validation map |

---

## 9. Common errors when porting

| Mistake | Fix |
|---------|-----|
| Sending JSON body | Use `x-www-form-urlencoded` |
| Skipping temp token | Register/login will fail |
| Using user token for register | Use **temp** token |
| Using temp token for profile-update | Use **login** token |
| Applying referral on Account via profile-update | Use **register**; Account apply needs backend API |
| Wrong `app_id` | Users won’t match; get app registered in AuthHub |
| Treating HTTP 200 as success | Check `status: true` in JSON |

---

## 10. Quick endpoint map

| Step | Method | Path | Bearer |
|------|--------|------|--------|
| Temp token | POST | `/api/temp-token` | — |
| Sign up (+ referral) | POST | `/api/register` | temp |
| Login | POST | `/api/login` | temp |
| Profile read | POST | `/api/profile` | temp (this app) |
| Profile update | POST | `/api/profile-update` | user |
| Forgot send OTP | POST | `/api/forgot-pwd/send-otp` | temp |
| Forgot verify OTP | POST | `/api/forgot-pwd/verify-otp` | — |
| Forgot reset | POST | `/api/forgot-pwd/reset-pwd` | — / as implemented |
| Delete account | POST | `/api/delete-account` | user |
| Apply referral (optional) | POST | `/api/apply-referral-code` | user |

---

*Generated from the NKJV-Bible AuthHub client implementation. For a new product, request your own `app_id` / client credentials from AuthHub before production.*
