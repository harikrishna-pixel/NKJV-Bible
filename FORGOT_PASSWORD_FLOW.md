# Forgot Password Flow - Complete Documentation

## 🔍 Overview
This document explains the complete forgot password functionality and how it's connected in the app.

---

## 📱 User Flow

1. **User Action**: Left Hamburger Menu → My Account → Forgot Password
2. **Enter Email**: User enters their email address
3. **Tap Reset Password**: System sends OTP to email
4. **Enter OTP**: User receives and enters OTP code
5. **Set New Password**: User creates a new password
6. **Success**: User is redirected to Login screen

---

## 🔗 Technical Flow & Connections

### 1. UI Layer
**File**: `lib/view/screens/authenitcation/view/forget_password_screen.dart`
- **Function**: User enters email and taps "Reset Password" button
- **Validation**: Email format validation using `FormBuilderValidators.email()`
- **Next**: Calls Bloc layer

### 2. Business Logic Layer (Bloc)
**File**: `lib/view/screens/authenitcation/bloc/forget_password_bloc.dart`
- **Provider**: `forgetPasswordBloc` (ChangeNotifierProvider)
- **Function**: `forgetPassword(context)`
- **Next**: Calls Auth Notifier

### 3. Notifier Layer
**File**: `lib/core/notifiers/auth/auth.notifier.dart`
- **Function**: `forgotsendotp({required email, context})`
- **Responsibilities**:
  - Calls API
  - Handles response
  - Shows error/success messages
  - Navigates to OTP screen on success
  - Stores email in cache for OTP verification
- **Next**: Calls API layer

### 4. API Layer
**File**: `lib/core/api/auth/register.api.dart`
- **Function**: `forgotsendotp({required email})`
- **Responsibilities**:
  - Constructs API URL
  - Sends HTTP POST request
  - Returns response or null on error
- **Next**: Uses HTTP client

### 5. HTTP Client
**File**: `lib/utils/custom_http.dart`
- **Function**: `postwithout(path, {data})`
- **Method**: POST with form-urlencoded
- **Timeout**: 30 seconds (newly added)
- **Headers**:
  ```
  Content-type: application/x-www-form-urlencoded
  Acess-Control-Allow-Origin: *
  ```

---

## 🌐 API Endpoint Details

### Base URL
```
https://bibleoffice.com/authhub/API/public/
```

### Endpoint
```
api/forgot-pwd/send-otp
```

### Full URL
```
https://bibleoffice.com/authhub/API/public/api/forgot-pwd/send-otp
```

### Request Data
```dart
{
  "email": "user@example.com",
  "app_id": "11656bd4-ed0c-11ef-b28e-fa163e8c011b"
}
```

### App ID Configuration
**File**: `lib/view/screens/dashboard/constants.dart`
```dart
class BibleInfo {
  static String appID = '11656bd4-ed0c-11ef-b28e-fa163e8c011b';
}
```

---

## 🛠️ Fixes Applied

### Problem
- Error: "Unable to Perform Service"
- Cause: API returning null, then trying to decode null as JSON

### Solution 1: Null Check
**File**: `lib/core/notifiers/auth/auth.notifier.dart`
- Added null check before JSON decoding
- Show proper error message when API returns null

### Solution 2: Timeout Handling
**File**: `lib/utils/custom_http.dart`
- Added 30-second timeout to HTTP requests
- Prevents indefinite waiting when server is down/slow
- Throws exception with clear error message on timeout

### Solution 3: Better Error Messages
- **Offline**: "No Internet Connection"
- **Server Error**: "Unable to connect to server. Please try again."
- **API Response**: Shows actual error message from server

### Solution 4: Enhanced Logging
**File**: `lib/core/api/auth/register.api.dart`
- Logs request URL, email, and app ID
- Logs response status code and body
- Identifies timeout exceptions specifically
- Helps with debugging connection issues

---

## 📊 Response Flow

### Success Response
```json
{
  "status": true,
  "message": "OTP sent successfully",
  "data": { ... }
}
```
**Action**: Navigate to OTP screen with success snackbar

### Error Response
```json
{
  "status": false,
  "message": "User not found",
  "data": null
}
```
**Action**: Show error snackbar with message

### Network Error (null response)
**Action**: Show error message:
- "No Internet Connection" (if offline)
- "Unable to connect to server. Please try again." (if online but can't reach server)

### Timeout (30+ seconds)
**Action**: Show error message and log timeout details

---

## 🔄 Complete OTP Flow

### Step 1: Send OTP
- **API**: `api/forgot-pwd/send-otp`
- **Screen**: `forget_password_screen.dart`
- **Next**: `otp_screen.dart`

### Step 2: Verify OTP
- **API**: `api/forgot-pwd/verify-otp`
- **File**: `register.api.dart` → `forgotverifyotp()`
- **Screen**: `otp_screen.dart`
- **Next**: `rest_password_screen.dart`

### Step 3: Reset Password
- **API**: `api/forgot-pwd/reset-pwd`
- **File**: `register.api.dart` → `forgotrestpwd()`
- **Screen**: `rest_password_screen.dart`
- **Next**: `login_screen.dart`

---

## 🧪 Testing Checklist

### Test Scenarios
- ✅ Valid email → Should send OTP
- ✅ Invalid email format → Should show validation error
- ✅ Non-existent email → Should show "User not found" error
- ✅ No internet → Should show "No Internet Connection"
- ✅ Slow network → Should timeout after 30s with clear message
- ✅ Server down → Should show "Unable to connect to server"

---

## 🐛 Debugging Tips

### Check Logs
Look for these log messages in console:
```
forgotsendotp - Request URL: [url]
forgotsendotp - Email: [email], AppID: [id]
req post body - [data]
forgotsendotp response: statusCode=[code]
forgotsendotp response body: [body]
```

### Common Issues
1. **"Unable to Perform Service"**
   - Fixed: Now shows proper error messages

2. **Timeout**
   - Check internet connection
   - Verify server is accessible at `bibleoffice.com`
   - Check logs for timeout exception

3. **Wrong App ID**
   - Verify `BibleInfo.appID` matches backend configuration

---

## 📝 Configuration Files

| File | Purpose |
|------|---------|
| `app_api_constant.dart` | API endpoints and base URL |
| `constants.dart` | App ID and app configuration |
| `custom_http.dart` | HTTP client with timeout |
| `auth.notifier.dart` | Business logic and navigation |
| `register.api.dart` | API calls and request formatting |
| `forget_password_bloc.dart` | State management |

---

## ✅ All Changes Made

1. ✅ Added null check in `auth.notifier.dart`
2. ✅ Added 30s timeout in `custom_http.dart`
3. ✅ Enhanced error messages throughout
4. ✅ Improved logging in `register.api.dart`
5. ✅ Better exception handling for timeouts
6. ✅ Used SnackbarUtil for consistent error display

---

**Status**: ✅ Forgot Password functionality is now working with proper error handling and timeout management.
