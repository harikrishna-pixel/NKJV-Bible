# Image picker + Avatar — port document

Use this file to copy **User DP / Avatar / Gallery** into another multi-screen Bible app.

This is **AuthHub profile photo**, not Prayer Wall Mongo. Prayer Wall only **reads** the cached URL and sends it on post.

**Do not change** library backup, verse DB, last-read, IAP, or `api/user-backup/*`.  
**Do not change** profile-update **action=4** (wallet). Photo uses **action=1** + **action=3** only.

---

## 1. What the user does

1. Open **Edit Bible Profile** (`EditProfileScreen`).
2. Tap the photo → sheet: **Avatar** or **Gallery**.
3. **Gallery** → system photo picker (not camera).
4. **Avatar** → 6 PNG grid → tap one.
5. Preview shows on the circle immediately (local file or asset).
6. Tap Save → name/email **action=1**, photo file **action=3**.
7. Server returns a **full image URL**. Cache key `profile_image`.
8. Account Profile, Prayer Profile, wall cards, and new posts use that URL.

Avatar is **not** stored as `assets/avatar png/...` in cache. It is copied to a **temp file** and uploaded like a gallery photo. Cache always holds an **http(s) URL**.

---

## 2. Files (copy / wire)

| File | Role |
|------|------|
| `lib/core/image_picker_mixin.dart` | Gallery pick + 20 MB check |
| `lib/view/screens/profile/view/edit_profile_screen.dart` | Avatar sheet, gallery, preview, `_resolveProfileImageFile`, Save |
| `lib/core/api/auth/profile_update.api.dart` | action=1 name/email; action=3 multipart; `loadAndCacheProfileImageUrl` |
| `lib/core/notifiers/auth/auth.notifier.dart` | `updateprofle` → cache `profile_image` from response |
| `lib/view/screens/profile/view/profile_screen.dart` | Account DP: `CachedNetworkImage` of cached URL |
| `lib/view/screens/prayer_wall/post_prayer_screen.dart` | Reads cache → `profile_image` on create |
| `lib/view/screens/prayer_wall/prayer_wall_service.dart` | Adds `profile_image` on `POST /api/prayers` if URL present |
| `lib/view/screens/prayer_wall/prayer_wall_models.dart` | `_extractProfileImage` from wall JSON |
| `lib/view/screens/prayer_wall/prayer_wall_screen.dart` | NetworkImage / initials on cards + own profile |
| `lib/view/screens/prayer_wall/prayer_wall_user_profile_screen.dart` | Other-user DP |
| `assets/avatar png/` | 6 avatars (folder name has a **space**) |

**Do not** replace `profile_update.api.dart` wholesale if the host already has action=1 / referral / action=4. Add **only** action=3 + URL parse + `loadAndCacheProfileImageUrl`. Leave library backup and action=4 as they are.

---

## 3. Assets + pubspec

Folder: `assets/avatar png/` (space in the name — keep it).

```
assets/avatar png/woman.png
assets/avatar png/man.png
assets/avatar png/cat.png
assets/avatar png/panda.png
assets/avatar png/bear.png
assets/avatar png/chicken.png
```

```yaml
assets:
  - assets/avatar png/

# already used in this app
image_picker: ^1.1.2
# Account Profile uses cached_network_image
```

Also used: `path_provider` (`getTemporaryDirectory`), `flutter/services` `rootBundle`.

---

## 4. Permissions (gallery only — no camera)

This app does **not** call `ImageSource.camera`.

**iOS** `Info.plist` (must exist or picker fails):

- `NSPhotoLibraryUsageDescription`
- `NSPhotoLibraryAddUsageDescription`

**Android** `AndroidManifest.xml`:

- `READ_EXTERNAL_STORAGE` (this app)
- On newer Android, `image_picker` uses the system picker; do not invent extra camera permission unless you add camera later.

Do **not** change other plist keys (backup, mic, tracking) when adding these.

---

## 5. Functions (every one)

### `ImagePickerMixin` — `lib/core/image_picker_mixin.dart`

`Future<XFile?> getImageFiles({bool? allowMultiple})`

- `ImagePicker().pickImage(source: ImageSource.gallery)`
- `allowMultiple` is unused
- If file `length() > 20_000_000` → toast `"The file may not be greater than 20 MB."` → `null`
- Cancel → `null`

### `EditProfileScreenState`

| Function | Logic |
|----------|--------|
| `_showProfilePhotoOptions()` | Bottom sheet: Avatar / Gallery |
| Gallery path | `getImageFiles()` → `pickedImage = file`, `selectedAvatarAsset = null` |
| Avatar path | `_showAvatarPicker()` |
| `_showAvatarPicker()` | 3-column grid of `_avatarAssets`. Tap → `selectedAvatarAsset = path`, `pickedImage = null` |
| `_resolveProfileImageFile()` | Gallery: `File(pickedImage.path)` if exists. Avatar: `rootBundle.load(asset)` → write `getTemporaryDirectory()/profile_avatar_<filename>` → that `File`. Else `null` |
| Preview in build | `pickedImage` → `Image.file`; else `selectedAvatarAsset` → `Image.asset`; else cached/Firebase URL; else initials |
| Save tap | If name/email not both empty: optional Firebase `editProfileBloc.uploadImage` **only when `pickedImage != null`**; then `_resolveProfileImageFile()`; then `AuthNotifier.updateprofle(..., profileImage: file)` |

`_avatarAssets` order: woman, man, cat, panda, bear, chicken.

### `ProfileUpdateApi`

| Function | Logic |
|----------|--------|
| `updateprofile(..., File? profileImage)` | POST action=**1** JSON: `email`, `name`, `action=1`, `user_id`, `app_id`. If `profileImage` exists → `_uploadProfileImageAction3` then `_mergeProfileImageUrl` into action=1 body |
| `_uploadProfileImageAction3` | `MultipartRequest` POST same `api/profile-update`. Fields: `action=3`, `user_id`, `app_id`. File field name **`profile_image`**. Types: jpg/jpeg, png, webp (max **15 MB** on server). Header `Authorization: Bearer <authtoken>`. Parse URL via `_profileImageFromBody` |
| `_profileImageFromBody` | Read `profile_image` / `profileImage` / `profile_image_url` / `image_url` / `photoURL` / `photo_url` at top, `data`, or `data.user` |
| `_mergeProfileImageUrl` | Inject URL into action=1 JSON so notifier can cache it |
| `loadAndCacheProfileImageUrl()` | If cache `profile_image` set → return it. Else snapshot action=1, parse URL, write cache |

**Do not** send the photo on action=1 as a path string. Action=1 is name/email. Photo is **action=3 multipart**.

### `AuthNotifier.updateprofle`

1. `profileUpdateApi.updateprofile(..., profileImage: file)`
2. If `status == true`: cache `user`, `name`
3. `_profileImageUrlFromResponse` → cache `profile_image`
4. If API has no URL: Firebase `photoURL` only if it already exists (do not invent)
5. This app then `Get.offAll(HomeScreen(From: "splash"))` — host may keep that or `Get.back()`; do not change IAP/Home internals

`_profileImageUrlFromResponse` also checks `avatar` / `avatar_url`.

### Account Profile — `ProfileScreen`

- `_loadProfileImage()` → `loadAndCacheProfileImageUrl()` → `_profileImageUrl`
- Circle: `CachedNetworkImage` or initials (`_safeInitials`)
- Logout: `removeCache(key: 'profile_image')`

### Prayer Wall (display + post only)

| Place | Logic |
|-------|--------|
| `post_prayer_screen` | `readCache('profile_image')` → `createPrayer(profileImage: url)` |
| `PrayerWallService.createPrayer` | If URL not empty, body `profile_image` |
| `PrayerWallItem._extractProfileImage` | Same keys as API + nested `user` / `postedBy` |
| Wall / hotspot / own profile / other profile | `NetworkImage(url)` or initials |
| Comments | **No DP** — do not add |

Follow list uses wall prayer `profileImage` when the id matches (see Prayer Wall logics doc).

---

## 6. APIs

**AuthHub (photo)**

```
POST https://bibleoffice.com/authhub/API/public/api/profile-update
```

| Action | Type | Fields |
|--------|------|--------|
| `1` | JSON | `email`, `name`, `action`, `user_id`, `app_id` (`BibleInfo.appID`) |
| `3` | multipart | `action=3`, `user_id`, `app_id`, file **`profile_image`** (jpg/jpeg/png/webp, ≤15MB) |
| `4` | JSON | `wallet_balance` — **do not use for photo** |

Auth: `Authorization: Bearer <authtoken>` (cache `authtoken`).  
`user_id` = cache `userid` (AuthHub id, **not** Prayer Wall resolve id).

**Prayer Wall (URL only)**

`POST https://api.biblehi.com/api/prayers` may include `profile_image: "<https url>"`.  
Do not upload the file to biblehi.

---

## 7. Cache keys

| Key | Value |
|-----|--------|
| `profile_image` | Full **https** URL after action=3 (or snapshot / Firebase fallback) |
| `name` | Display name (action=1) |
| `user` | Email |
| `userid` | AuthHub id for action=3 |
| `authtoken` | Bearer token |

**Never** write `assets/avatar png/cat.png` into `profile_image`. Wall `NetworkImage` will break.

---

## 8. Where the photo shows

| Screen | Source |
|--------|--------|
| Edit Profile preview | Local file / asset, then URL |
| Account Profile | Cache URL via `loadAndCacheProfileImageUrl` |
| Prayer Profile (own) | Same cache |
| Wall / hotspot / other profile | Prayer row `profile_image` from API |
| New post | Cache URL at submit time |
| Comments | Initials only |

---

## 9. Multi-screen wiring (host already has Profile)

1. Copy `assets/avatar png/` + pubspec folder + `image_picker` if missing.
2. Copy / merge `ImagePickerMixin`.
3. Port Edit Profile photo sheet + `_resolveProfileImageFile` + Save calling `updateprofle` with the `File`.
4. Add action=3 in host `ProfileUpdateApi` **without** touching backup or action=4.
5. After successful update, cache `profile_image` URL.
6. Account Profile: `CachedNetworkImage` of that URL.
7. Prayer Wall: already reads cache on post + `NetworkImage` on cards — keep that.
8. Logout: clear `profile_image`.

Do not rebuild Home, library, or login for this.

---

## 10. Rules / mistakes to avoid

- Gallery only. No camera unless you add it later.
- Avatar must become a **temp file** then action=3. Do not POST an asset path.
- action=1 = name/email. action=3 = file. Do not mix wallet action=4.
- Cache URL, not asset path.
- Comments stay without DP.
- Do not change library backup upload/download.
- Folder name is `avatar png` (space). Paths must match exactly.

---

## 11. Checklist

- [ ] 6 avatars in `assets/avatar png/` and listed in pubspec
- [ ] Tap photo → Avatar / Gallery
- [ ] Gallery ≤ 20 MB client; server ≤ 15 MB
- [ ] Save uploads file on action=3
- [ ] Cache `profile_image` is https
- [ ] Account + Prayer Profile + wall show the photo
- [ ] New prayer sends the URL
- [ ] Logout clears cache
- [ ] Library backup and IAP unchanged

If this file and code disagree, **follow the code**.
