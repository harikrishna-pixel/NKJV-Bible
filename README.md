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

---

## Work log — 15 Sep 2026 (port to other apps)

Use this section when copying today’s work into another Bible app from the same Flutter source. Prefer **UI / analytics wiring only** unless the other app has the same bug.

### 1) Analytics Phase 1 — Firebase + Mixpanel (common service)

**Goal:** One `AnalyticsService` so screens never call Firebase / Mixpanel SDKs directly. Both providers optional per app.

**Files to copy / mirror**

| File | Role |
|------|------|
| `lib/services/analytics/analytics_config.dart` | Per-app ON/OFF + Mixpanel project token |
| `lib/services/analytics/analytics_events.dart` | Central event + property names (Phase 2 ready) |
| `lib/services/analytics/analytics_service.dart` | Dual fan-out: Firebase Analytics + Mixpanel |
| `pubspec.yaml` | Add `mixpanel_flutter` (Firebase Analytics already used) |

**Config (per app)** — edit `AnalyticsConfig`:

```dart
static bool enableFirebaseAnalytics = true;   // or false
static bool enableMixpanelAnalytics = true;   // or false
static String mixpanelToken = '...';          // project token ONLY
static bool sendPhase1TestEvent = true;       // set false after verified
```

**Old Paper Bible (this app):** both Firebase + Mixpanel **enabled**.

**Security**

- Put **Mixpanel project token** in the app only.
- **Never** put Mixpanel **API Secret** in the client (server/API use only).

**Init (already in this app)**

- `lib/main.dart` → `_bootstrapBackgroundStartup()` calls `AnalyticsService.initialize()`.
- On init, Phase 1 sends `analytics_phase1_test` to enabled providers and Mixpanel `flush()`.

**Verify**

1. Run app once.
2. Mixpanel Live View → `analytics_phase1_test`.
3. Firebase DebugView → same event.

**Not done yet (Phase 2+)** — do **not** invent random events in screens. Use names in `analytics_events.dart` later for:

- Onboarding (`onboarding_started`, step viewed/completed/skipped/completed + durations)
- Screen / feature (`screen_viewed`, `screen_exited`, `feature_used` — exclude background time)
- Paywall (`paywall_viewed` / closed / plan / purchase_* + `paywall_source`)
- No private content (chat text, notes, search text, etc.)

**Port checklist**

1. Add `mixpanel_flutter` + copy the three analytics files.
2. Set `AnalyticsConfig` flags/token for that app.
3. Ensure `AnalyticsService.initialize()` runs at startup (same as `main.dart` here).
4. Keep existing `trackHomeScreen` / `trackPaywallScreen` etc. — they now dual-send when enabled.
5. Confirm Phase 1 test event, then turn `sendPhase1TestEvent = false` if desired.

---

### 2) Bugs fixed today (UI / display — keep existing business logic)

#### A) Paywall price display (multi / AR paywall)

**Problem:** Other-country stores showed wrong high USD hardcodes, or blank `/month` when hardcodes were removed. Buy path was fine; UI price binding was wrong.

**Fix (display only):** Prefer StoreKit `product.price`; if missing, keep previous hardcode fallbacks; requery products when preload misses a plan. “Works out to …” monthly line uses **rounded** whole number (display only).

**Files:** `lib/view/screens/multi_select_paywall.dart` (and related price getters on `multi_select_paywallscreen.dart` if that app uses it).

**Port:** Copy the `_loadProducts` requery + `_aiPrice` / `_lifetimePrice` / `_aiNote` display fallbacks — do **not** change purchase / product ID logic.

#### B) “No content for this chapter” empty UI

**Problem:** Home showed empty-chapter message + Retry when verses were empty after fetch/fallback (e.g. Mark 2).

**Fix (UI only):** Keep provider/DB fallback logic in `_buildEmptyContentWithChapters`; replace empty message UI with the same **Loader** as loading state. Users no longer see that empty screen.

**File:** `lib/view/screens/dashboard/home_screen.dart`

**Note:** If verses never load, loader can stay a long time — root cause is still sync/DB/index, not the UI swap.

#### C) Verse image share — branding alignment

**Problem:** Share/Save action bar reserve pushed branding mid-image in Screenshot capture.

**Fix:** `actionBarReserve: 0` so Share/Save/Close stay outside the screenshot.

**File:** `lib/view/widget/home_content_edit_bottom_sheet.dart`

#### D) Widgets hub / how-to UX

**Fixes (UI / navigation presentation):**

- Larger Continue Reading preview; removed outer beige boxes.
- Single AppBar back; scroll to top when opening how-to/gallery.
- “View Available Widgets” from prompt opens full Widgets hub (all widgets), not a single-widget path.

**Files:** `lib/view/screens/dashboard/add_widget_intro_screen.dart`, `lib/home_widget/widget_how_to_add_screen.dart`

#### E) Prayer share custom bottom sheet

**Status:** Custom prayer share sheet was tried, then **undone** on request. Share is back to original system `Share.share` text flow. Do **not** port the custom sheet unless product asks again.

---

### 3) Explicitly out of scope today

- Full onboarding / screen-time / paywall funnel event wiring (Phase 2).
- Mixpanel API Secret in client.
- Changing Amen / credits / IAP purchase logic.
- Removing empty-chapter **loading** forever (only the empty **message** UI was removed).

---

### 4) Quick “copy to other app” order

1. Analytics Phase 1 files + `mixpanel_flutter` + config flags/token + init.
2. Paywall price display helpers (if same multi paywall).
3. Home empty-chapter UI → loader (if same `_buildEmptyContentWithChapters`).
4. Verse share `actionBarReserve: 0` (if same share screenshot).
5. Widgets hub UX (if same widget intro screens).
