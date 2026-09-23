# Port README — Prayer Wall, Profiles, Widget Hub, Reading Progress, Connection Insights

Use this file to copy these features into **another multi-screen Bible app**.

This is the **NLT** app in this repo (`BibleInfo.ios_Bundle_Id` = `com.balaklrapps.newlivingtranslation`, `bible_shortName` = `NLT Bible`). Folder name may say NKJV — follow `BibleInfo`, not the folder name.


**Do not overwrite the existing project `README.md`.** That file documents library cloud backup. Library backup is **out of scope** for this port.

---

## 0. How to use this in a multi-screen app

The target app already has Home, drawer, reader, Profile, login, library.

**Copy feature folders + wire drawer/Profile rows. Do not replace Home, reader, library, IAP, or login.**

| Do | Do not |
|----|--------|
| Copy the files listed per feature | Rewrite `HomeScreen` / reader / mark-as-read persist |
| Change **only** `BibleInfo.ios_Bundle_Id` and `BibleInfo.bible_shortName` | Change library backup, verse zip/DB, last-read, IAP |
| Hook drawer callbacks that already exist here | Invent new Prayer Wall API paths or payload keys |
| Keep Prayer Profile and Account Profile as **two screens linked by rows** | Merge them into one profile |

Copy **one feature at a time** (order in §9). After each feature, the host app’s existing screens must still work.

---

## 1. NEVER TOUCH (host app must keep these)

Do **not** copy-over or rewrite these when porting:

| Area | Why |
|------|-----|
| Library backup | `lib/core/library_backup_upload_service.dart`, `.enc` / cloud zip, `README.md` backup section |
| Verse zip / verse SQLite bootstrap | `lib/core/bible_extract_paths.dart`, `extract_zip_json.dart`, `assets/zipped/**` |
| Last-read persist | `SharPreferences.selectedBook` / `selectedChapter` / `selectedBookNum` write path |
| Mark-as-read **write** | `DashBoardController.persistMarkChapterReadProgress` / unmark + `verse.is_read` loops |
| Streak **increment** | `StreakService.recordActivity` (Faith Journey day, not chapter reads) |
| IAP / paywall / restore / coins | `SubscriptionScreen`, StoreKit, wallet grant |
| AuthHub login/signup internals | Only **call** resolve after login; do not change login payload |
| `pubspec.yaml` versions | Add **asset folders + Georgia font** only if the host is missing them. Ask before changing packages |

Reading Progress and Connection Insights are **read-only dashboards**. They read existing data. They must not become a second mark-as-read or streak engine.

---

## 2. Per-app identity (only change these)

In the **target** app `constants.dart` / `BibleInfo`:

```dart
ios_Bundle_Id   // e.g. com.balaklrapps.newlivingtranslation
bible_shortName // e.g. NLT Bible
```

Prayer Wall writes merge:

```json
{
  "app_id": "<BibleInfo.ios_Bundle_Id>",
  "app_name": "<BibleInfo.bible_shortName>",
  "bundle_id": "<BibleInfo.ios_Bundle_Id>"
}
```

into **create / update / delete prayer, likes, comments, reports** via `PrayerWallService._encodeBody`.

**Follow and block do not send app meta** (raw JSON only). See §4.

Widget App Group (iOS) must match the **target** bundle:

```
group.<same as ios_Bundle_Id>
```

in Dart (`bible_home_widget.dart` `_kAppGroupId`), Runner entitlements, and Widget Extension entitlements.

---

# PART A — Prayer Wall

## 3. Files to copy

### Required (copy the whole folder)

```
lib/constant/prayer_wall_api_constant.dart
lib/view/screens/prayer_wall/prayer_wall_service.dart
lib/view/screens/prayer_wall/prayer_wall_models.dart
lib/view/screens/prayer_wall/prayer_wall_local_store.dart
lib/view/screens/prayer_wall/prayer_wall_screen.dart
lib/view/screens/prayer_wall/post_prayer_screen.dart
lib/view/screens/prayer_wall/prayer_wall_user_profile_screen.dart
lib/view/screens/prayer_wall/prayer_wall_comments_sheet.dart
lib/view/screens/prayer_wall/prayer_wall_login_required_dialog.dart
lib/view/screens/prayer_wall/prayer_wall_join_sheet.dart
lib/view/screens/prayer_wall/prayer_wall_guidelines_dialog.dart
lib/view/screens/prayer_wall/prayer_wall_verify_dialogs.dart
lib/view/screens/prayer_wall/prayer_wall_report_dialog.dart
lib/view/screens/prayer_wall/prayer_wall_status_dialog.dart
lib/view/screens/prayer_wall/prayer_share_screen.dart
lib/view/screens/prayer_wall/prayer_wall_home_expiry_banner.dart
```

### Also copy (notifications — additive)

```
lib/services/prayer_wall_activity_notifier.dart
lib/services/prayer_wall_background.dart
android/app/src/main/res/drawable/ic_prayer_wall_notif.png
```

### Host wiring (do not replace host files — add the same hooks)

| Host file | Hook |
|-----------|------|
| Drawer | `onPrayerWallTap` → `Get.to(() => const PrayerWallScreen())` |
| Settings | row → same |
| `ProfileScreen` | row **Prayer Profile** → `PrayerWallScreen(openMyProfile: true)` |
| `EditProfileScreen` | already used for name/photo/country cache (`name`, `profile_image`, `country`) |
| Login / signup success | `PrayerWallService.resolveIdentityUser(email:, userName:)` then cache identity. **Logged-in resolve: email + user_name only. Do not send `device_id`.** |
| Logout | `PrayerWallLocalStore.snapshotBlockedIdsForEmail()` then `clearAccountScopedData()` |
| `main.dart` | `PrayerWallBackgroundScheduler` + resume `PrayerWallActivityNotifier.checkAndNotify()` |
| Home reader (optional) | `PrayerWallHomeExpiryBanner` |
| Prayer Guidance (optional) | open `PostPrayerScreen` / `PrayerWallScreen` |
| Embedded login | `PrayerWallEmbeddedAuthHost` — **never `Get.offAll` from embedded Prayer Wall login** (destroys wall stack) |

### Do not invent

- New API hosts or path names
- New block/follow body keys
- Credit deduct on post (UI credits are display-only; `WalletService.deductCredits` stays commented)

---

## 4. Prayer Wall API

**Host:** `https://api.biblehi.com`  
**All Prayer Wall HTTP headers:**

```
Content-Type: application/json
Authorization: marberx@123tech
```

### Identity

| Call | Method | Body | Notes |
|------|--------|------|-------|
| `/api/users/resolve` | POST | Logged-in: `{ app_id, email, user_name? }` Guest: `{ app_id, device_id, user_name? }` | Raw JSON. Returns `user_id`. Cache as `identityUserId`. This is **not** AuthHub `userid`. |

Use resolve `user_id` as:

- `identityUserId` on create prayer
- `user_id` on block / follow
- `excludeBlockedForUserId` on wall GET
- `user_id` on prayer-history GET

### Prayers

| Call | Method | Encoding |
|------|--------|----------|
| `/api/prayers` | GET | Guest = full list. Logged-in: `?excludeBlockedForUserId=<resolve user_id>` (fallback to plain GET if that query fails) |
| `/api/prayers?identityUserId=` | GET | My active prayers |
| `/api/prayers?prayerId=` | GET | One prayer |
| `/api/prayers` | POST | `_encodeBody`: `prayer_title`, `prayer_description`, `prayer_category`, `isAnonymous`, `prayer_duration` (7/14/30), optional `user_name`, `profile_image`, `email`, `identityUserId` |
| `/api/prayers` | PATCH | `_encodeBody`: `prayerId` + `_id` + `id`, `prayer_title`, `prayer_description`. Fallback `PATCH/PUT /api/prayers/{id}` |
| `/api/prayers` | DELETE | `_encodeBody`: `prayerId` + `_id` + `id`. Fallback path delete |
| `/api/prayer-history?user_id=` | GET | Expired / past for resolve id |

`prayer_description` may be dual:

```
<<<MY_WORDS>>>
<user text>
<<<AI_PRAYER>>>
<English prayer>
```

Helpers: `PrayerDualDescription` in `prayer_wall_models.dart`. Wall cards show AI text. Do not show `MY_WORDS` / `AI_PRAYER` tags in UI.

### Queue / hotspot

| Call | Method | Notes |
|------|--------|-------|
| `/api/prayer-queue` | GET | Coming up + waiting. **Not** filtered by block on the server |
| `/api/prayer-queue/current` | GET | Current hotspot. **Not** filtered by block on the server |

App hides blocked/reported items in UI. Timer: prefer `slotEndsAt`, else `msRemaining`. Display `MM:SS`. When left ≤ 0, refresh queue. Default slot ~420s if missing.

**Block on hotspot (viewer only):** A blocks B → A’s device shows next unblocked prayer as hotspot; timer still follows the **current slot**. Other devices still see B if B is current. One-way (see block).

### Likes / comments / report

| Call | Method | Body |
|------|--------|------|
| `/api/likes` | GET | optional `?prayerId=` |
| `/api/likes` | POST | `_encodeBody` `{ prayerId }` |
| `/api/likes` | DELETE | `_encodeBody` `{ likeId }` or `{ prayerId }` |
| `/api/comments` | GET | optional `?prayerId=` |
| `/api/comments` | POST | `_encodeBody` `{ prayerId, comment_text, isAnonymous: true }` |
| `/api/comments` | PATCH / DELETE | `_encodeBody` + id keys; path fallback on 404 |
| `/api/prayer-reports` | POST | `_encodeBody` `{ prayerId, reporter_id, report_reason }` |

- Like: login required. Local map `prayer_wall_like_map_v1`.
- View comments: open. Post comment: login. Edit/delete only ids in `prayer_wall_my_comment_ids_v1`. Max 1000 chars.
- Report: guests allowed (`reporter_id` = AuthHub `userid` or device id). Local hide only.

### Block (one-way)

| Call | Method | Body |
|------|--------|------|
| `/api/blocked-users` | POST | Raw `{ user_id, blocked_user_id, name?, blocked_user_name? }` |
| `/api/blocked-users` | DELETE | Raw `{ user_id, blocked_user_id }` |
| `/api/blocked-users?user_id=` | GET | People **this viewer** blocked |

`user_id` = viewer resolve id. `blocked_user_id` = prefer `identityUserId` then `authorUserId`.

**A blocks B:** A does not see B. B still sees A unless B also blocks A. Do **not** POST a reverse row (that would put A on B’s Blocked list).

Local hide: `_blockedUserIds` stores person id + their prayer ids. Empty GET must not wipe local blocks. Blocked tab counts **people**, not every prayer id.

### Follow / unfollow

| Call | Method | Body / query | Parse |
|------|--------|--------------|-------|
| `/api/follows` | POST | Raw `{ user_id, following_user_id }` | 2xx or body contains `already followed` = success |
| `/api/follows` | DELETE | Raw same | unfollow |
| `/api/follows?user_id=` | GET | who this user follows | top-level `following_user_ids`, `count` |
| `/api/follows/followers?user_id=` | GET | who follows this user | top-level `follower_user_ids`, `count` |

IDs = resolve `user_id`.

**UI**

- Other profile: Follow / Followed (`PrayerWallUserProfileScreen._toggleFollow`). Guest → snackbar sign in. Own profile: no Follow button (ids must match).
- Tap **Followers** or **Following** (own Prayer Profile + other profile) → `showPrayerWallFollowPeopleSheet`.
- List = existing GET ids. Name + photo = match `wallPrayers` (`identityUserId` or `authorUserId`, skip anonymous). No match → **Community member**.
- Name API is **not** wired yet. When you add it later, only enrich the sheet. Do not change POST/DELETE follow.

**Known limits (do not “fix” unless asked)**

- Profile open prefers `authorUserId` then `identityUserId`. Own stats use resolve id. If those differ, counts can stay 0.
- Follow GET parser is top-level ids only (no `data` wrapper).
- Own Following count can be stale until Prayer Profile reloads.

### AI (not biblehi)

`POST https://combine-api-ruby.vercel.app/api/chat`  
Header: `Content-Type: application/json` only (no Prayer Wall Authorization).  
Body: `{ "input": "<prompt>" }`  
Used by `formatPrayerInEnglish` and `validatePrayerContent`.

---

## 5. Prayer Wall UI logics (implement the same)

1. **Wall** — `GET /api/prayers` (+ exclude blocked). Category filter. Like + comment counts.
2. **Hotspot** — current + coming up + waiting. Countdown from `slotEndsAt`.
3. **Post** — login → join sheet first time → title, category, duration 7/14/30 → Type Your Prayer (max 300) → AI English prayer → Review → validate → `POST /api/prayers`. Do not deduct wallet.
4. **Anonymous** — API field exists; post toggle is off in this app (`_isAnonymous = false`). Comments still post `isAnonymous: true`. Anonymous card: no profile tap.
5. **My Prayers** — Current / Expired / Blocked. Ownership = email match or resolve id or local `myPrayerIds`.
6. **Edit / delete** — owner only.
7. **Block / report** — ⋮ on card or other profile menu.
8. **Other profile** — tap name/avatar. Recent prayers from the wall list passed in. Follow + block.
9. **Join terms** — `prayer_wall_join_terms_accepted_v1` (survives logout).
10. **Georgia font** — `pubspec` only `weight: 500`. `FontWeight.w700` / `w800` is fake-bold (can look doubled). Do not add a second Georgia Bold TTF unless asked.
11. **iPad** — Type Your Prayer layout is iPad-only (`shortestSide >= 600`). Keep that when copying `post_prayer_screen.dart`.

### Guest vs login

| Action | Guest |
|--------|--------|
| View wall, queue, comments | Yes |
| Like, post comment, post prayer, block, follow | No — login dialog / snackbar |
| Report | Yes |

Logged-in = cache `authtoken` or `userid` non-empty.

### Cache keys used with Prayer Wall

| Key | Use |
|-----|-----|
| `user` | email on create + ownership |
| `name` | `user_name` + Prayer Profile |
| `userid` | report `reporter_id` when logged in |
| `authtoken` | login detect |
| `profile_image` | post + avatars |
| `country` | Prayer Profile line |

### Local store keys (`prayer_wall_local_store.dart`)

Copy the file as-is. Important keys: like map, my comment ids, author maps, my prayer ids, duration meta, reported ids, blocked (device + per-email), identity `prayer_wall_identity_user_id_field_v2`, join terms.

`clearAccountScopedData()` on account switch — do not change API payloads when calling it.

---

## 6. Prayer Wall assets + font

Copy folder `assets/prayer_wall/` and keep this `pubspec` entry:

```yaml
- assets/prayer_wall/
```

| File | Where |
|------|--------|
| `prayer_profile_bg.png` | My Prayer Profile / Blocked |
| `hotspot_prayer_bg.jpg` | Hotspot (fallback `prayer_review_bg.png`) |
| `prayer_type_bg.png` | Type Your Prayer |
| `prayer_review_bg.png` | Review |
| `prayer_review_card_bg.png` | Review card |
| `prayer_wall_join_icon.png` | Join sheet |
| `prayer_wall_join_success.png` | Join success (code uses PNG) |
| `prayer_wall_join_success.gif` | In folder; PNG used in UI |
| `edit_bible_profile_bg.jpg` | `EditProfileScreen` |

Font (if host missing):

```yaml
- family: Georgia
  fonts:
    - asset: assets/fonts/GEORGIA.ttf
      weight: 500
```

Avatars (Edit Profile / Account DP) are `assets/avatar png/` — only if you also port User DP. Not required for wall feed.

Theme: brown `#5C4033`, cream `#FFF9F3` / `#F5F0E6`.

---

# PART B — Prayer Profile linked to Account / Reading Profile

These are **two profiles**. Link them. Do not merge.

```
Account Profile (ProfileScreen)
  └─ row "Prayer Profile"
       └─ PrayerWallScreen(openMyProfile: true)
            └─ Prayer Profile (My Prayers + Followers/Following + Blocked)

Prayer Profile
  ├─ avatar → EditProfileScreen (name / photo / country)
  └─ row "Account Profile" → ProfileScreen
        (reading, library, backup — do not rebuild backup here)

Wall card name/avatar (not anonymous)
  └─ PrayerWallUserProfileScreen (other user)
```

| | Prayer Profile | Account Profile | Edit Bible Profile |
|--|----------------|-----------------|--------------------|
| Screen | `PrayerWallScreen` `_showingHistory` | `ProfileScreen` | `EditProfileScreen` |
| Shows | name, photo, country, prayers shared, followers, following, recent / expired / blocked | email, library, backup, logout, wallet, **link to Prayer Profile** | name, photo, country |
| Data | cache + resolve + wall/history + follow GETs | AuthHub + library | profile-update API (action=1 name/email, action=3 photo) |

If opened with `openMyProfile: true`, back from Prayer Profile returns to Account Profile (`Get.back()`).

**Reading Profile** in this app = Account Profile (reading / library). There is no third “Reading Profile” screen. Reading Progress is a **Journey** screen, not a profile.

---

# PART C — Reading Progress

**Display only.** Reads book/verse progress that the host already writes on Mark as Read.

### Files

```
lib/view/screens/journey/reading_progress_screen.dart
lib/view/screens/journey/reading_activity_list_screen.dart
lib/view/screens/journey/journey_parchment.dart
lib/services/reading_activity_service.dart
assets/journey/reading_progress_bg.png
```

`pubspec`: `- assets/journey/`

### Drawer

`onReadingProgressTap` → `Get.to(() => const ReadingProgressScreen())`

### UI

1. Keep Going hero (`reading_progress_bg.png`)
2. Bible Completed % / Chapters Read / Books Completed (`book.read_per`, `verse.is_read`)
3. Reading Streak card if streak > 0 → `DailyJourneyScreen` (count is **Faith Journey** streak, not chapters)
4. Currently Reading → host Home chapter open (`Get.offAll(HomeScreen(From: 'Chapter', ...))` — keep host contract)
5. Recent Activity (3 + View All) → `ReadingActivityListScreen`

### Data

| Source | Use |
|--------|-----|
| SQLite `book.read_per`, `verse.is_read` | % and counts — **read only** |
| `SharPreferences.selectedBook` / `selectedChapter` / `selectedBookNum` | Currently Reading — **read only** |
| `reading_recent_activity` | Recent Activity JSON |
| `StreakService.getCurrentStreak()` | Streak card — **do not increment here** |

### Host hook (one line, after **existing** mark-as-read persist)

`ReadingActivityService.recordFromController(...)` — same as this app after `persistMarkChapterReadProgress`.

**Do not** port a new mark-as-read writer. **Do not** increment streak from this screen.

---

# PART D — Connection Insights

**No Prayer Wall API. Local only.**

### Files

```
lib/view/screens/journey/connection_insights_screen.dart
lib/view/screens/journey/connection_checkin_calendar_screen.dart
lib/services/connection_checkin_store.dart
```

### Drawer

`onConnectionInsightsTap` → `ConnectionInsightsScreen`

### Data

- Prefs key `connection_checkin_by_day` — `YYYY-MM-DD` → level `0..4` (Very Far → Very Close)
- On load, hydrate from Faith Journey `streak_flow_item_by_day` → `connectionSliderValue` via `ConnectionCheckinStore.levelFromSlider()`
- `ConnectionCheckinStore.record()` exists; live path is Faith Journey slider

### UI

- Range pills **7 / 30 / 90** days
- Per-level % bars, dominant level, motivation card
- Recent check-ins (3 + View All)
- Info icon → month calendar with level colors

**Do not** change Faith Journey slider save, streak increment, or the old `CalendarScreen`.

If the host has no Faith Journey, you must either port that slider step or call `ConnectionCheckinStore.record` from the host’s check-in UI. Do not invent a server API.

---

# PART E — Widget Hub

iOS home widgets + in-app hub. Android sync functions are **no-ops** (`if (!Platform.isIOS) return`).

### Flutter files

```
lib/home_widget/bible_home_widget.dart
lib/home_widget/widget_prompt_service.dart
lib/home_widget/widget_prompt_cards.dart
lib/home_widget/widget_how_to_add_screen.dart
lib/home_widget/widget_preview_gallery_screen.dart
lib/view/screens/dashboard/add_widget_intro_screen.dart
```

### Assets

```
assets/bible_widget/
assets/bible_widget_comopressed/
assets/home icons/Widgets.png
```

`pubspec`: those folders. Package `home_widget` — **ask before adding** if the host `pubspec` does not have it.

### Drawer

`onWidgetsTap` → `AddWidgetIntroScreen()`  
Chip = installed count. Attention dot = `WidgetPromptService`.

### Init / deep link

- `initBibleHomeWidget()` from `main.dart`
- Home handles URI (`getBibleWidgetRouteFromUri`) → verse / reading / prayer / chat / streak / random
- Scheme: `biblebookapp://<host>?homeWidget`
- Prayer Wall notification payload `open_prayer_wall` is **app** navigation, not a home-widget kind

### iOS native (copy target; do not invent new kinds)

```
ios/BibleHomeWidget/
ios/Shared/StreakLiveActivityAttributes.swift
ios/Shared/ContentLiveActivityAttributes.swift
ios/Runner/StreakLiveActivityManager.swift
ios/Runner/ContentLiveActivityManager.swift
```

See also `docs/IOS_HOME_WIDGET_SETUP.md` (App Group in that doc may be stale — **use the target bundle**).

### Kinds in this app

Daily Verse, Continue Reading, Weekly Reading Streak, Favorite Verse, Hourly Verse, Random Verse, Verse Image, Bible Prayer, Bible Chat + Live Activities (streak / continue reading / memory verse).

Continue Reading widget **reads** last-read prefs + `book.read_per`. Weekly Streak widget **reads** Faith Journey streak. Prompts are additive — they must not change streak, IAP, ads, or mark-as-read eligibility.

---

# PART F — Copy order (multi-screen host)

Do this in order. After each step, run the host app and confirm old screens still work.

### 1) Identity only

Set target `BibleInfo.ios_Bundle_Id` and `bible_shortName`. Do not change IAP ids unless that app already uses them.

### 2) Reading Progress (safest)

1. Copy journey screens + `reading_activity_service.dart` + `assets/journey/`
2. Wire drawer `onReadingProgressTap`
3. After **existing** mark-as-read persist, record recent activity
4. Do not touch verse DB bootstrap or last-read writes

### 3) Connection Insights

1. Copy insights + calendar + `connection_checkin_store.dart`
2. Wire drawer
3. Confirm Faith Journey still writes `connectionSliderValue` (or host equivalent)

### 4) Widget Hub (iOS)

1. Copy Flutter hub + assets
2. Wire drawer + `initBibleHomeWidget` + Home URI
3. Copy iOS Widget Extension + App Group = target bundle
4. Leave Android as no-op

### 5) Prayer Wall

1. Copy `lib/view/screens/prayer_wall/**` + `prayer_wall_api_constant.dart` + `assets/prayer_wall/` + Georgia if missing
2. Wire drawer / Settings
3. After login: resolve (email + name, no `device_id`)
4. Logout: snapshot blocked + `clearAccountScopedData`
5. Embedded login: no `Get.offAll`
6. Optional: notifications + Home expiry banner

### 6) Link profiles

1. Account Profile → `PrayerWallScreen(openMyProfile: true)`
2. Prayer Profile → Account Profile row + avatar → Edit Bible Profile
3. Keep library backup only on Account Profile

---

# PART G — Checklist

- [ ] Host library backup still works (export / import / cloud) — **you did not edit it**
- [ ] Mark as Read still saves the same way; streak still only from Faith Journey
- [ ] Last-read / Continue Reading still the same prefs
- [ ] Drawer: Reading Progress, Connection Insights, Widgets, Prayer Wall
- [ ] Prayer Wall: post, like, comment, hotspot timer, block (one-way), follow/unfollow, Followers/Following list
- [ ] Follow list shows wall name/DP or Community member
- [ ] Account Profile ↔ Prayer Profile rows
- [ ] Target `app_id` / `app_name` / `bundle_id` on prayer writes
- [ ] Widget App Group matches target bundle (iOS)

---

# PART H — What this README is not

- Not a rewrite of IAP / AR paywall
- Not a library backup port
- Not a new follow-name API (app-side list first; plug names later)
- Not a two-way block (backend would need to hide A for B without putting A on B’s Blocked list)

Source of truth is the files listed above in this repo. If this README and code disagree, **follow the code**.
