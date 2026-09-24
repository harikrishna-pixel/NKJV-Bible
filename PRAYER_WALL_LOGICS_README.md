# Prayer Wall + Hotspot logics

Implement **these exact logics** in the other app. Do not invent new APIs or change library backup, verse DB, last-read, or IAP.

**Host:** `https://api.biblehi.com`  
**Headers (every Prayer Wall HTTP):**

```
Content-Type: application/json
Authorization: marberx@123tech
```

**Per-app only:** `BibleInfo.ios_Bundle_Id` + `BibleInfo.bible_shortName`  
Writes that use `_encodeBody` also send `app_id`, `app_name`, `bundle_id`.

Queue + current + follow + block writes do **not** send app meta (raw JSON / GET only).

---

# PART 1 — Hotspot prayer (every logic)

Hotspot is **not** the wall list. It is a **server rotation queue**. The app only displays it and hides blocked/reported items **for this viewer**.

## 1.1 APIs (do not change paths)

| Call | When | What |
|------|------|------|
| `GET /api/prayer-queue/current` | Wall open + every slot end | Current slot: `prayer`, `position`, `nextPrayerId`, `slotSeconds`, `slotStartedAt`, `slotEndsAt`, `msRemaining`, `queueCount`, `loops` |
| `GET /api/prayer-queue` | Same time (parallel) | Full list: `items[]` (`position`, `isCurrent`, `prayer`), same slot fields |

Both are **not** filtered by block on the server. Guest and logged-in get the same queue.

**Do not** send `excludeBlockedForUserId` on queue. That query is **only** for `GET /api/prayers`.

Functions: `PrayerWallService.fetchPrayerQueueCurrent()`, `fetchPrayerQueue()`.  
Parse: `PrayerQueueCurrentResult`, `PrayerQueueListResult` in `prayer_wall_models.dart`.  
Default `slotSeconds` if missing = **420** (7 min).

## 1.2 When the app loads queue

On `PrayerWallScreen` init: `unawaited(_refreshQueue())` **immediately** — do not wait for wall GET.

`_refreshQueue()`:

1. `Future.wait([ current, list ])`
2. Save `_queueCurrent`, `_queueList`
3. `_queueSlotEndsAt = current.slotEndsAt ?? list.slotEndsAt`
4. Start `_armQueueTickTimer()`
5. On fail: show error + Retry (only if both are still null)

Pull-to-refresh also calls `_refreshQueue()` with the wall.

## 1.3 Timer (MM:SS)

**Prefer `slotEndsAt` over `msRemaining`.**

```
_queueMsRemaining:
  if _queueSlotEndsAt != null:
    left = slotEndsAt.toLocal() - now
    return max(0, left)
  else:
    return current.msRemaining ?? list.msRemaining ?? 0
```

Display: `_formatQueueCountdown` → `MM:SS` (minutes padded, seconds padded).

**1-second tick** (`_armQueueTickTimer`):

- If no `slotEndsAt`: `setState` only (clock still redraws if you later have ends).
- If `left <= 0`: cancel timer, call `_refreshQueue()` again.
- Else: `setState` so the pill counts down.

**00:00 is correct when remaining is 0.** If the same prayer stays on 00:00, the **backend** is still returning that prayer as current with a past/zero slot. The app must not invent a new hotspot. Waiting cards can still show `STARTS IN 7 MIN` because that uses `slotSeconds` (420) + current remaining 0.

UTC `slotEndsAt` without `Z` can parse as local and look already past → 00:00 + refresh loop. Still prefer `slotEndsAt` (this app’s rule).

## 1.4 Who is the Hotspot card (`_queueHotspotPrayer`)

Order:

1. `_queueCurrent.prayer` if **not** blocked by this viewer
2. Else the list item with `isCurrent == true` if not blocked
3. Else `_nextUnblockedQueuePrayer()` (next after current position; wrap if `loops`)

Blocked / reported never show as hotspot **on this device**. Other devices still see the real current slot.

**Timer always follows the server slot** (`_queueSlotEndsAt`), even if this viewer skipped a blocked current prayer. A can see C as hotspot while the clock is still B’s slot.

## 1.5 Coming Up Next (`_queueComingUpNext`)

1. If `nextPrayerId` is set, find that id in `list.items`, skip if blocked or same as shown hotspot
2. Else next unblocked after current (`_nextUnblockedQueuePrayer(skipPrayerId: hotspot id)`)
3. Badge: **UP NEXT**
4. Empty: `No upcoming prayer.`

## 1.6 In Waiting (`_queueWaitingOrdered`)

From `list.items`, drop:

- `isCurrent`
- blocked (this viewer)
- reported (this device)
- `nextPrayerId` / shown Coming Up / shown Hotspot (no duplicates)

Sort by `position`. Order = after current position, then wrap (before current) when `loops`.

Header: `IN WAITING • {queueCount} PRAYERS`  
Show **3**, then **View All >** / **Show Less**.  
Empty: `No prayers waiting.`

**STARTS IN** label (`_formatStartsInLabel`):

```
steps = position - currentPosition
if steps <= 0 and loops: steps = queueCount - currentPosition + position
totalSec = (steps - 1) * slotSeconds + floor(msRemaining/1000)
if totalSec <= 0 → "Soon"
mins = ceil(totalSec / 60)
1 min → "STARTS IN 1 MIN"
else → "STARTS IN {mins} MIN"
```

This is **estimated from slot length**, not a second countdown per waiting card.

## 1.7 Next unblocked helper (`_nextUnblockedQueuePrayer`)

Candidates: not current, not blocked, not reported, not `skipPrayerId`.  
First with `position > current`.  
If none and `loops`: first candidate.  
Else null.

## 1.8 Hotspot UI

- Background: `assets/prayer_wall/hotspot_prayer_bg.jpg` (fallback `prayer_review_bg.png`)
- Name, time, DP / initials
- Title: `prayer_title`, max **5 words**
- Subtitle: AI / my words / plain — line1 **5 words**, line2 **4 words**, then `...`
- Countdown pill: `MM:SS` from `_queueMsRemaining`
- Like + comment (same wall APIs)
- CTA brown `#3A2B18`
- Tap → `_QueuePrayerDetailScreen(fromHotspot: true)` title **Hotspot Prayer**
- Waiting / coming up tap → same detail, `fromHotspot: false`, title **Prayer**
- Double-tap guard: `_openingQueueDetail`

Anonymous hotspot: no profile tap (toast).

## 1.9 Block + hotspot (implement this)

| Who | This device | Other devices |
|-----|-------------|----------------|
| A blocks B, B is current | A sees next unblocked as hotspot; **timer still B’s slot** | Still B as hotspot until server rotates |
| A’s wall / coming up / waiting | B hidden | B still visible |
| B’s app | A still visible (block is **one-way**) | — |

Queue APIs stay unfiltered. Hide is UI (`_isItemBlocked` + reported set).

Do **not** POST a reverse block (would put A on B’s Blocked list).

## 1.10 What Hotspot must not do

- Do not write the queue
- Do not change slot length in the app
- Do not skip 00:00 by picking a random prayer
- Do not mix wall GET sort into the queue
- Do not deduct credits for being in hotspot

---

# PART 2 — Prayer Wall logics (everything implemented)

## 2.1 Identity

`POST /api/users/resolve`

- Logged-in: `{ app_id, email, user_name? }` — **no `device_id`**
- Guest: `{ app_id, device_id, user_name? }`

Returns `user_id`. Cache `prayer_wall_identity_user_id_field_v2`.  
This is **not** AuthHub `userid`.

Use resolve id as: create `identityUserId`, block/follow `user_id`, wall `excludeBlockedForUserId`, history `user_id`.

Call resolve after login/signup. Logout: snapshot blocked by email, then `clearAccountScopedData()`.

## 2.2 Wall feed

`GET /api/prayers`  
Logged-in: `?excludeBlockedForUserId=<resolve id>`. If that fails → plain GET.

`_visible`:

- Hide reported (this device only)
- Hide blocked (this viewer)
- Category chip (`All` or category)
- Sort: newest, or **Most prayed** = like count then newest

Wall is independent of hotspot. Same prayer can be on both.

## 2.3 Create / edit / delete

**Create** `POST /api/prayers` (`_encodeBody`):

`prayer_title`, `prayer_description`, `prayer_category`, `isAnonymous`, `prayer_duration` (7 / 14 / 30), optional `user_name`, `profile_image`, `email`, `identityUserId`

Flow:

1. Login required
2. Join sheet once (`prayer_wall_join_terms_accepted_v1`, survives logout)
3. Title + category + duration
4. Type Your Prayer (max 300) → AI `formatPrayerInEnglish` → Review
5. Dual body:

```
<<<MY_WORDS>>>
<user text>
<<<AI_PRAYER>>>
<English prayer>
```

6. `validatePrayerContent` + verify dialogs
7. Local: `addMyPrayerId`, duration meta, author maps
8. **Do not deduct wallet** (credits on UI are display only)

**Anonymous:** API field exists; this app posts `_isAnonymous = false` (toggle off). Comments still `isAnonymous: true`.

**Edit / delete:** owner only. `PATCH` / `DELETE` with `prayerId` + `_id` + `id`, path fallback on 404.

**Owner (`_isMyPrayer`):** prayer email == login email, else resolve id == `identityUserId`, else local `myPrayerIds` / author maps.

**AI host (not biblehi):** `POST https://combine-api-ruby.vercel.app/api/chat` `{ "input": "..." }` — no Prayer Wall Authorization.

**iPad only** (`shortestSide >= 600`): Type Your Prayer layout. Do not change phone layout.

**Georgia:** font file weight **500** only. `w700` / `w800` is fake-bold (can look doubled). Do not add Georgia Bold unless asked.

## 2.4 My Prayers / history / expiry

- Current: identity GET + device ids + email match; not duration-expired
- Expired: `GET /api/prayer-history?user_id=` + items with `expiresAt` or `createdAt + prayer_duration`
- After exact `postedAt + durationDays`: status dialog (UI only, no status API)
- Home optional: `PrayerWallHomeExpiryBanner`

## 2.5 Likes

- `GET /api/likes` counts
- `POST /api/likes` `{ prayerId }` — login
- `DELETE` `{ likeId }` or `{ prayerId }`
- Local `prayer_wall_like_map_v1`

## 2.6 Comments

- View: anyone
- Post: login, `{ prayerId, comment_text, isAnonymous: true }`, max 1000
- Edit/delete: only `prayer_wall_my_comment_ids_v1`
- Sheet: `PrayerWallCommentsSheet`

## 2.7 Report

`POST /api/prayer-reports` `{ prayerId, reporter_id, report_reason }`  
Guest OK (`reporter_id` = AuthHub `userid` or device id).  
Local hide only — other users still see it.

## 2.8 Block / unblock (one-way)

| Call | Body |
|------|------|
| POST `/api/blocked-users` | `{ user_id, blocked_user_id, name?, blocked_user_name? }` raw |
| DELETE | `{ user_id, blocked_user_id }` raw |
| GET `?user_id=` | this viewer’s list only |

`blocked_user_id` = `identityUserId` then `authorUserId`.

Local: store person id + all their prayer ids. Empty GET must **not** wipe local. Blocked tab = **people**, not every id.

**A → B:** A hides B (wall + hotspot + waiting). B still sees A.  
To hide both ways: backend must drop A on B’s wall/queue **without** putting A on B’s Blocked list. App must not reverse-POST.

## 2.9 Follow / unfollow

| Call | Body / parse |
|------|----------------|
| POST `/api/follows` | `{ user_id, following_user_id }` raw. `already followed` = success |
| DELETE | same |
| GET `/api/follows?user_id=` | `following_user_ids`, `count` |
| GET `/api/follows/followers?user_id=` | `follower_user_ids`, `count` |

- Other profile: Follow / Followed. Guest → sign in. Own profile (ids match): no button
- Tap Followers / Following → `showPrayerWallFollowPeopleSheet`
- Names/photos: match wall prayers (`identityUserId` / `authorUserId`, skip anonymous). Else **Community member**
- Name API not wired yet — do not change follow POST/DELETE when you add it later

## 2.10 Profiles (two screens)

```
Account Profile (ProfileScreen)  ← reading / library / backup
  └─ row "Prayer Profile" → PrayerWallScreen(openMyProfile: true)

Prayer Profile (My Prayers + Followers/Following + Blocked)
  ├─ avatar → EditProfileScreen (name, photo, country)
  └─ row "Account Profile" → ProfileScreen

Wall name/avatar (not anonymous)
  └─ PrayerWallUserProfileScreen (follow + block + recent from wall list)
```

Do **not** merge profiles. Do **not** put library backup on Prayer Profile.

`openMyProfile: true` → back returns to Account Profile.

## 2.11 Guest vs login

| Guest can | Guest cannot |
|-----------|----------------|
| View wall, queue, comments | Like, post comment, post prayer, block, follow |
| Report | |

Login = cache `authtoken` or `userid`.  
Embedded Prayer Wall login: **never `Get.offAll`** (keeps wall stack).

## 2.12 Display name / DP

- Card name: API name; own prayer → cache `name`; anonymous → Anonymous
- DP: prayer `profile_image`; own → cached `profile_image`
- Post sends cache name + photo URL (action=3 upload lives on Edit Profile, not wall)

## 2.13 Notifications (additive)

`PrayerWallActivityNotifier` + `PrayerWallBackgroundScheduler`  
Poll likes/comments/new prayers. Payload can open wall (`open_prayer_wall`).  
Must not change like/comment/post APIs.

## 2.14 Local keys (copy `prayer_wall_local_store.dart`)

Like map, my comments, author maps, my prayer ids, duration meta, status submitted, reported, blocked (device + per email + display names), identity v2, join terms, reporter id, home banner dismiss.

---

# PART 3 — Assets (used)

```
assets/prayer_wall/hotspot_prayer_bg.jpg
assets/prayer_wall/prayer_review_bg.png
assets/prayer_wall/prayer_profile_bg.png
assets/prayer_wall/prayer_type_bg.png
assets/prayer_wall/prayer_wall_join_icon.png
assets/prayer_wall/prayer_wall_join_success.png
assets/prayer_wall/edit_bible_profile_bg.jpg   // EditProfileScreen
```

In folder but **not** used by UI: `prayer_review_card_bg.png`, `prayer_wall_join_success.gif`.

`pubspec`: `- assets/prayer_wall/`  
Georgia `assets/fonts/GEORGIA.ttf` weight 500.

---

# PART 4 — Files to copy

```
lib/constant/prayer_wall_api_constant.dart
lib/view/screens/prayer_wall/   (entire folder)
```

Wire only: drawer → `PrayerWallScreen`, Account → `openMyProfile: true`, login resolve, logout clear, optional notifier + expiry banner.

---

# PART 5 — Do not touch

Library backup, verse zip/DB, last-read, mark-as-read persist, streak increment, IAP, AuthHub login internals (only call resolve after success).

If this file and code disagree, **follow the code**.
