# Last 2 weeks — APIs and client logic (handoff)

**Purpose:** Copy this file onto another branch as the spec of what the NKJV Prayer Wall client already does (≈ 14 Aug – 29 Aug 2026).

**Do not treat this as a rewrite ticket.** Adding this markdown does not change Dart, HTTP, or UI. On the other branch, **keep existing Prayer Wall / login / widget behavior** unless you are fixing a confirmed bug. Match these APIs and rules; do not invent new endpoints or change IDs “for cleanliness.”

| Item | Value |
|------|--------|
| Branch this was taken from | `nkjv-main` |
| Window | 2026-08-14 → 2026-08-29 |
| Prayer Wall `app_id` / `bundle_id` | `com.balaklrapps.newkingsjamesversion` (`BibleInfo.ios_Bundle_Id`) |
| Login/register `app_id` | UUID `BibleInfo.appID` (unchanged; **not** sent on Prayer Wall writes) |

---

## How to use this on another branch

1. Copy **only this file** (or keep it under `docs/`).
2. Do **not** paste snippets into production code “to refresh” working screens.
3. If you implement Prayer Wall there, wire the **same URLs, query names, and ID rules** below.
4. Additive pattern used here: new query params / extra body fields / extra local keys. Wall `GET /api/prayers` without filters still exists as guest + fallback.

---

## What shipped in this window (product)

**Prayer Wall (majority of commits)**

- Identity via `POST /api/users/resolve` (email + device + optional Firebase UID).
- Full wall, likes, comments, report, share, edit/delete own posts.
- **My Prayers** by `identityUserId` + login email; **Sort: Current | Expired**.
- Expired list from duration (`expiresAt` / `createdAt + prayer_duration`) plus `GET /api/prayer-history`.
- Block / unblock, restore after login, per-email local snapshot, Login Required for guests.
- Logged-in wall: `GET /api/prayers?excludeBlockedForUserId=`.
- Join-terms bottom sheet (once per install).
- AI check before post (`combine-api` chat).
- Prayer Wall writes use **bundle id** as `app_id`, not the login UUID.
- Login-from-wall: pop so Login Required does not stick.

**Also in the same ~2 weeks (not biblehi Prayer Wall)**

- Home widgets hub / widget intro / ads.
- Profile image on wall cards when the API returns `profile_image`.

Those widget/ad surfaces do **not** use `/api/prayers`. Do not mix them into Prayer Wall HTTP.

---

## 1. Hosts and headers

| Host | Use |
|------|-----|
| `https://api.biblehi.com` | Prayers, comments, likes, reports, blocks, resolve, prayer history |
| `https://combine-api-ruby.vercel.app` | AI moderation before publish; same URL as Chat / Prayer Guidance |

**biblehi:** `Content-Type: application/json` plus `Authorization` from `PrayerWallService._jsonHeaders` (keep whatever the branch already uses; do not invent a new token in docs).

**Chat/AI:** `Content-Type: application/json` only. **No** biblehi `Authorization`.

Every Prayer Wall **write** (POST/PATCH/DELETE prayers, likes, comments, reports) merges app meta via `_encodeBody`:

```json
{
  "app_id": "com.balaklrapps.newkingsjamesversion",
  "app_name": "NKJV Bible",
  "bundle_id": "com.balaklrapps.newkingsjamesversion"
}
```

**Exception:** `POST` / `DELETE` `/api/blocked-users` send **only** `{ "user_id", "blocked_user_id" }` — no app meta.

**Defined, unused by wall UI:** `GET https://api.biblehi.com/health`

**Source:** `lib/constant/prayer_wall_api_constant.dart`, `lib/view/screens/prayer_wall/prayer_wall_service.dart`

---

## 2. Identity — `POST /api/users/resolve`

**When:** After login/register, and whenever the wall needs a stable id (`ensureIdentityUserId`).

**URL:** `https://api.biblehi.com/api/users/resolve`

**Body (typical):**

```json
{
  "app_id": "com.balaklrapps.newkingsjamesversion",
  "email": "<login email>",
  "device_id": "<Android androidInfo.id or iOS identifierForVendor>",
  "firebaseId": "<optional Firebase UID>"
}
```

- Omit empty fields (`firebaseId`, `email`, `device_id` only if present).
- Timeout: **15 seconds**.
- Client reads `user_id` (also `userId`, or nested `data.user_id`).
- Saved locally: `prayer_wall_identity_user_id_field_v2`.
- That value is sent as **`identityUserId`** on create prayer and as **`user_id`** on block GET/POST/DELETE and prayer-history.

**Critical server/client coupling:** The same install always sends the **same `device_id`**. If the backend keys identity on device, **two emails on one phone can share one `user_id`**. Then:

- `GET /api/blocked-users?user_id=` returns one shared list.
- `excludeBlockedForUserId` uses that same id.

Do **not** “fix” this on a copy branch by swapping Block to login UUID unless GET restore, Unblock, and feed exclude all use **that same id**. Mixed IDs = blocks that never restore / never unblock.

---

## 3. Prayers — feed and CRUD

**Base:** `https://api.biblehi.com/api/prayers`

### 3.1 `GET /api/prayers`

Unfiltered wall. Used for **guests** and as **fallback** if the exclude-blocked GET is not 2xx.

### 3.2 `GET /api/prayers?excludeBlockedForUserId=<resolve user_id>`

**When:** Viewer is logged in **and** a resolve `user_id` is available (cache or resolve).

**Intended server behavior:** Hide prayers this user blocked **and** prayers from people who blocked them (two-way feed). Own posts and everyone else still appear.

**Client:** Non-2xx → retry unfiltered `GET /api/prayers`.

**Does not apply to:** likes GET/POST, comments GET/POST. Those stay open even if the card is hidden on the wall.

### 3.3 `GET /api/prayers?identityUserId=<resolve user_id>`

**When:** **My Prayers → Current**.

Then client keeps only rows whose `email` matches **login email** (identity GET may return extra rows).

If resolve id is missing → return `[]` (do not dump the full wall into My Prayers).

### 3.4 `GET /api/prayers?prayerId=<prayer _id>`

**When:** Reload a locally posted id (history merge).

Server may ignore the query and return a list. Client keeps the row whose `_id` matches. If that fails, may fall back to full `GET /api/prayers` and filter by the posted-id set.

### 3.5 `POST /api/prayers`

Create. Body fields (plus app meta):

| Field | Notes |
|--------|--------|
| `prayer_title` | required |
| `prayer_description` | required |
| `prayer_category` | required |
| `isAnonymous` | bool |
| `prayer_duration` | days, default 7 |
| `user_name` | when available (even if anonymous flag is true) |
| `profile_image` | URL when available |
| `email` | login email when available |
| `identityUserId` | resolve `user_id` |

Credits/duration UI may exist locally; **duration is sent** as `prayer_duration`.

### 3.6 `PATCH /api/prayers`

Edit title/description. Body includes `prayerId`, `_id`, `id` (same value) plus new title/description.

On **404**, fallback: `PATCH /api/prayers/{id}` then `PUT /api/prayers/{id}`.

### 3.7 `DELETE /api/prayers`

Body: `prayerId` / `_id` / `id`. On 404: `DELETE /api/prayers/{id}`.

### Parsed prayer fields (client)

`_id` (or `id`), title, description, category, `isAnonymous`, author name, `authorUserId`, `email`, `identityUserId`, `profile_image`, `createdAt`, `expiresAt`, `prayer_duration`.

**Wall list does not hide expired posts.** Expiry is for home banners, owner status prompt, and **My Prayers → Sort: Expired**.

---

## 4. Prayer history — expired My Prayers

### `GET /api/prayer-history?user_id=<resolve user_id>`

**When:** Reload **My Prayers**. Timeout 15s. Missing id → skip, return `[]`.

Parse list from body, or nested `expired` / `expired_prayers` / `history` / `prayer_history` (including under `data`).

**UI:** Top tabs **My Prayers | Blocked**. Inside My Prayers, **Sort: Current | Expired**.

- **Current:** identity GET + locally posted ids, **not** duration-expired.
- **Expired:** `isDurationExpired` (`expiresAt` or `createdAt + prayer_duration` days) **or** history-only rows with no duration fields (treated as expired).

Wall sort stays **Latest / Most prayed** (not Current/Expired).

---

## 5. Likes

**Base:** `https://api.biblehi.com/api/likes`

| Method | URL | Role |
|--------|-----|------|
| GET | `/api/likes` | Count per `prayerId` |
| GET | `/api/likes?prayerId=` | Latest like `_id` for unlike |
| POST | `/api/likes` | Body `{ "prayerId" }` + app meta |
| DELETE | `/api/likes` | `{ "likeId" }` or `{ "prayerId" }` + app meta |

- 201 → parse like `_id`. 200 “already liked” → GET by prayerId for an id.
- Device map `prayer_wall_like_map_v1`: prayer id → like document id (unlike after restart).
- Login required to like.
- Block **does not** disable like APIs.

---

## 6. Comments

**Base:** `https://api.biblehi.com/api/comments`

| Method | URL | Role |
|--------|-----|------|
| GET | `/api/comments` | Counts (list of rows with `prayerId`) |
| GET | `/api/comments?prayerId=` | Thread |
| POST | `/api/comments` | `prayerId`, `comment_text`, `isAnonymous` + app meta |
| PATCH | `/api/comments` | `commentId` / `_id` / `id` + text fields; 404 → path `/comments/{id}` PATCH then PUT |
| DELETE | `/api/comments` | same id shape; 404 → path delete |

Own comment ids: `prayer_wall_my_comment_ids_v1` (edit/delete after restart). Login required.

---

## 7. Reports

### `POST /api/prayer-reports`

```json
{
  "prayerId": "<prayer _id>",
  "reporter_id": "<stable device id, max 128 chars>",
  "report_reason": "<reason>",
  "app_id": "...",
  "app_name": "...",
  "bundle_id": "..."
}
```

Reported ids: `prayer_wall_reported_prayer_ids_v1`. Hidden **on this device only** (not a global delete).

---

## 8. Block / unblock

**Base:** `https://api.biblehi.com/api/blocked-users`

### 8.1 `POST /api/blocked-users`

```json
{
  "user_id": "<viewer's resolve user_id>",
  "blocked_user_id": "<target>"
}
```

**`blocked_user_id` pick order (do not reverse):**

1. Card `identityUserId` if it looks like a 24-char hex Mongo id  
2. Else `authorUserId`  
3. Else prayer `_id`

Also store prayer `_id` locally so the Blocked tab can still match cards.

### 8.2 `DELETE /api/blocked-users`

Same JSON. If the stored target is a user id but a legacy row used prayer `_id`, client may DELETE both.

Unblock is allowed even if resolve cache is empty: use session fallback so the button still works.

### 8.3 `GET /api/blocked-users?user_id=<resolve user_id>`

Restore after login. Timeout 15s.

Parse `blocked_user_id` / `blockedUserId` from list, `blocked_user_ids`, `blocked_users`, `items`, or `data`.

**Replace** the in-memory blocked set with this GET (do **not** union another email’s leftover ids).

**Logout:** Snapshot active blocked ids under **login email** (`prayer_wall_blocked_user_ids_by_email_v1`), then clear the active device list.

**Login:** Load that email’s snapshot, then **replace** from GET.

**Guest:** Block is visible on others’ posts; tap → **Login Required**, then confirm + POST.

**Local hide:** A card is blocked if the local set matches `_id` **or** `identityUserId` **or** `authorUserId`. This complements `excludeBlockedForUserId` on the feed.

**Empty Blocked tab copy:** “No blocked profiles”.

---

## 9. AI validation (post prayer)

### `POST https://combine-api-ruby.vercel.app/api/chat`

```json
{ "input": "<moderation prompt including title + details>" }
```

Response: `output` string (`VALID` or `INVALID|vulgar|…` / `INVALID|not_prayer|…`). Legacy Gemini-shaped `output` still parsed.

**On AI/network failure → allow publish** (do not block posting if the moderator is down).

Same host is used for in-app Chat / Prayer Guidance (`input` / `output`). Changing that URL is a product change, not required to copy Prayer Wall.

---

## 10. Screen logic (no extra APIs)

| Area | Behavior |
|------|----------|
| **Prayer Wall** | Category chips; sort Latest / Most prayed; FAB post; hide reported + locally blocked |
| **Post Prayer** | Must be logged in; join-terms sheet **once per install** (`prayer_wall_join_terms_accepted_v1`, **not** cleared on logout); AI validate; POST; success UI |
| **My Profile / My Prayers** | Login; tabs My Prayers \| Blocked; sort Current \| Expired |
| **Ownership (`_isMyPrayer`)** | Same login email on the prayer, **else** resolve `identityUserId` (email-scoped so two accounts don’t share “mine”), **else** local posted ids / author map |
| **Home expiry banner** | Wall fetch + local duration meta; “ends today” / “has ended”; dismiss keys |
| **Status dialog** | After owner duration expires (local meta) |
| **Share** | In-app share (prayer id / title / body) |
| **Login Required** | Like, comment, post, block (guest). After login, `Navigator.pop` so the sheet does not stick |
| **Infinite spinner** | Do not await heavy block restore before first paint; restore GET can finish after `_loading = false` |

**Logout / account switch:** `clearAccountScopedData()` drops my-prayer ids, author maps, identity cache, duration meta, **active** blocked list, likes map, etc. **Email-keyed blocked backup is kept.** Join-terms flag is kept.

---

## 11. Local storage (SharedPreferences)

| Key | Purpose |
|-----|---------|
| `prayer_wall_identity_user_id_field_v2` | Resolve `user_id` |
| `prayer_wall_my_prayer_ids_v1` | Posted ids this session/account |
| `prayer_wall_duration_meta_v1` | Expiry prompts / owned duration |
| `prayer_wall_blocked_user_ids_v1` | Active blocked set |
| `prayer_wall_blocked_user_ids_by_email_v1` | Per-email backup |
| `prayer_wall_like_map_v1` | Unlike ids |
| `prayer_wall_my_comment_ids_v1` | Edit/delete comments |
| `prayer_wall_reported_prayer_ids_v1` | Hide reported |
| `prayer_wall_join_terms_accepted_v1` | Join sheet (survives logout) |
| `prayer_wall_reporter_id_v1` | Report `reporter_id` |
| `prayer_wall_home_banner_dismiss_v1` | Home banner dismiss |
| `prayer_wall_prayer_author_map_v1` | Fallback author names |
| `prayer_wall_prayer_author_user_id_map_v1` | Poster user id for block |
| `prayer_wall_last_display_name_v1` | Display name cache |
| `prayer_wall_seen_prayer_ids_v1` | Seen ids |
| `prayer_wall_status_submitted_ids_v1` | Status dialog already shown |

---

## 12. Quick API index

| Method | Path |
|--------|------|
| POST | `/api/users/resolve` |
| GET | `/api/prayers` |
| GET | `/api/prayers?excludeBlockedForUserId=` |
| GET | `/api/prayers?identityUserId=` |
| GET | `/api/prayers?prayerId=` |
| POST / PATCH / DELETE | `/api/prayers` |
| GET / POST / DELETE | `/api/likes` |
| GET | `/api/likes?prayerId=` |
| GET / POST / PATCH / DELETE | `/api/comments` |
| GET | `/api/comments?prayerId=` |
| POST | `/api/prayer-reports` |
| GET | `/api/blocked-users?user_id=` |
| POST / DELETE | `/api/blocked-users` |
| GET | `/api/prayer-history?user_id=` |
| POST | `https://combine-api-ruby.vercel.app/api/chat` |

---

## 13. Known limits (do not “fix” unless product asks)

1. **Two emails, one device, one resolve `user_id`:** Hari can see Ragul’s **server** Blocked list. Local per-email snapshot only stops **client merge**; it does not split the server list.
2. **Likes/comments** are not gated by `excludeBlockedForUserId`. Mutual hide of those needs API support.
3. **Guests** always get unfiltered `GET /api/prayers`.
4. **Unblock after delete own prayer + reinstall:** often leftover rows keyed by old prayer `_id` or a resolve id that changed.
5. Using login `userid` for Block **only works** if GET restore, Unblock, and feed exclude use that **same** id.

---

## 14. Source files (reference, do not rewrite blindly)

| File | Role |
|------|------|
| `lib/constant/prayer_wall_api_constant.dart` | URLs |
| `lib/view/screens/prayer_wall/prayer_wall_service.dart` | HTTP |
| `lib/view/screens/prayer_wall/prayer_wall_screen.dart` | Wall + My Prayers + Block UI |
| `lib/view/screens/prayer_wall/prayer_wall_local_store.dart` | Prefs |
| `lib/view/screens/prayer_wall/prayer_wall_models.dart` | Parse rows / expiry |
| `lib/view/screens/prayer_wall/post_prayer_screen.dart` | Create + AI + join terms |
| `lib/view/screens/prayer_wall/prayer_wall_join_sheet.dart` | Terms sheet |
| `lib/view/screens/dashboard/constants.dart` | `BibleInfo` bundle vs UUID |
| `lib/view/screens/profile/view/profile_screen.dart` | Logout snapshot + clear |

---

## 15. How to verify a call (debug)

Search console for:

- `========== GET /api/prayers ==========` (logged-in URL should include `excludeBlockedForUserId`)
- `========== POST /api/users/resolve ==========`
- `PrayerWallService.blockUser body` / GET blocked-users
- `========== GET /api/prayer-history ==========`
- `========== POST PRAYER ==========`

---

## 16. Commits in this window (git, `nkjv-main`)

```
f95d164  2026-08-29  modify the prayerwall screen
4dc91ab  2026-08-28  modifly prayerwall screen
88c0579  2026-08-28  modifly block logics
fbe122f  2026-08-27  modification in prayerwall
1f81713  2026-08-27  prayerwall modifiction in api
6861358  2026-08-27  added block account option
d7faad0  2026-08-26  prayerwall history implemention
03044f8  2026-08-20  slove bugs i widgets hub
4fd2a20  2026-08-20  update code
d28be53  2026-08-20  modify widgets hub
d165117  2026-08-20  modify widgets hub
e2dac95  2026-08-18  modify prayerwall slove some bugs
6ccd2e6  2026-08-14  Added Ads and Widgets
d0d831d  2026-08-14  Added widgets
```

---

*Documentation only. Generated from the Prayer Wall client as of bundle-style `app_id`, exclude-blocked feed, history + Current/Expired sort, and account-scoped block restore.*
