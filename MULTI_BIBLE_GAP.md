# Multi-Bible gap: `multi_screeen` vs `all-bible`

This file lists what `multi_screeen` does and what `all-bible` is still missing.
Use it to port the behavior onto `all-bible`. Do not replace whole files.
`BibleInfo.folders.length > 1` means multi-Bible mode.

Folders differ on purpose:

| Branch | `BibleInfo.folders` |
|---|---|
| `multi_screeen` | `NKJV`, `catholic` |
| `all-bible` | `NLT Bible`, `TAMIL_Bible` |

Keep the `all-bible` folder names. Do not copy the NKJV / Catholic list over them.

---

## Already on `all-bible` (leave these)

- Settings row **Bible Version** and the drawer item (`showBibleVersion` when `folders.length > 1`).
- Drawer Upgrade opens `MultiSelectPaywall` when `folders.length > 1`.
- Old / New Testament split: last 27 books are the New Testament.
- Audio and text-to-speech read `BibleVersionConfig` (`lib/utils/bible_version_config.dart`). `multi_screeen` only has English vs Portuguese helpers. Keep the config file.
- `displayBookReadPercent` and `_chapterLoadGeneration` in `DashBoardController`.
- Helper files exist but are not wired in: `bible_book_resolve.dart`, `bible_ui_labels.dart`, `library_verse_flags_sync.dart`, `library_bible_guard.dart`, `library_bible_version_tag.dart`.

`all-bible` also has `paywallShows = 2` and `lib/view/screens/paywall_navigation.dart`. `multi_screeen` does not. Onboarding on `all-bible` still follows `paywallShows`, which is why the old paywall and the old toast appear.

---

## 1. Boxes and toasts still on the old path

### 1.1 “Are you sure? All my library data will be deleted.”

File: `lib/view/screens/bible_select_screen.dart`

On `all-bible`, Home Continue still calls `showClearDatabaseDialog`, and Okay calls `clearAllData()` (deletes bookmark, highlight, underline, save_notes, save_images). The button text is `loading...`.

On `multi_screeen`:

- That call is commented out. The box does not open.
- `clearAllData()` is not called. Library rows stay.
- Home Continue runs `_runHomeBibleSwitchFlow()` directly.
- Toast after the switch: `Updated Successfully`.

### 1.2 “A Beautiful Step Forward!”

Same file, `CustomAlertBox`.

On `all-bible` the dialog still shows (icon, title, “You've chosen a version…”, **Next**).

On `multi_screeen` `CustomAlertBox.show` does not build a dialog. It runs the same Next callback immediately (opens `PreferenceSelectionScreen`).

### 1.3 Rating box on Set as Default

On `all-bible`, choosing the default Bible still calls `_requestReview()`.

On `multi_screeen` that call is commented out on this screen. The rating dialog is not part of Bible Version.

### 1.4 Continue button

On `multi_screeen` only:

- Gray `#B8B0A6` until one row is `DownloadButtonState.active` (`hasPrimarySelected`).
- Gold gradient after that.
- If Continue is pressed with no folder: toast `Click Set as Default` (both branches have this toast).
- While switching, `_bibleSwitchProgressBar` sits **above** the button (gold `#D4A04A → #C59434 → #9A6B2F`, white `NN%`).
- `if (isloading == true) return;` so a second tap does nothing.

Row buttons are the same on both branches: **Download**, **Downloading...**, **Set as Default**, **Active**.

### 1.5 Purchase toasts

File: `lib/view/screens/intro_subcribtion_screen.dart`

| | `multi_screeen` | `all-bible` |
|---|---|---|
| Nothing to restore | `No purchases available to restore.` once | `No active subscription available` |
| Restore worked | `Restore Successful` | `Restore Success` |
| Buy worked | `Purchase Successful` | `Purchase Successful` |

On `multi_screeen`, after `Restore Successful` the “no purchases” toast is suppressed (`_restoreSuccessToastShown`). If the user is already premium, that toast is skipped. The invisible purchase host closes on no internet or a restore exception.

### 1.6 Free-trial copy

`lib/view/screens/free_trial_intro_screen.dart` and `free_trail_screen.dart`:

- `multi_screeen`: `Cancel \nanytime`
- `all-bible`: `Cancel \ngitanytime`

---

## 2. Paywall route

### Onboarding — `preference_selection_screen.dart`

When internet and product data exist, the “ready” Continue button:

```dart
if (BibleInfo.folders.length > 1) {
  Get.offAll(() => FreeTrialIntroScreen(
    sixMonthPlan: sixMonthPlan,
    oneYearPlan: oneYearPlan,
    lifeTimePlan: lifeTimePlan,
  ), transition: SubscriptionScreen.paywallRouteTransition,
     duration: SubscriptionScreen.paywallRouteDuration);
} else {
  Get.offAll(() => SubscriptionScreen(
    sixMonthPlan: sixMonthPlan,
    oneYearPlan: oneYearPlan,
    lifeTimePlan: lifeTimePlan,
    checkad: 'onboard',
  ), ...);
}
```

`all-bible` always calls `PaywallNavigation.buildVisiblePaywall(...)`. That uses `paywallShows`, so it opens the existing paywall even when two Bibles are installed.

`FreeTrialIntroScreen` / `FreeTrailScreen` Continue opens `MultiSelectPaywall` with the same plan ids.

`multi_screeen` home drawer and free-trial trail import `multi_select_paywallscreen.dart`. `free_trial_intro_screen.dart` imports `multi_select_paywall.dart`. Both classes are named `MultiSelectPaywall`. On `all-bible`, keep a single import (`multi_select_paywall.dart` is what `PaywallNavigation` and Home already use). Do not import both files in one library.

Home drawer Upgrade on `all-bible` already branches on `folders.length > 1`. Leave that path.

---

## 3. Home Bible switch — `bible_select_screen.dart`

`_runHomeBibleSwitchFlow()` order and progress:

| % | Step |
|---|---|
| 5 | `extractFromFolder(..., from: "home")` |
| 15 | `loadBookContent` — rebuilds `verse`, then `LibraryVerseFlagsSync.reapplyToVerseTable()` |
| 27 | `loadBookList` |
| 43 | `_savePreferences()` |
| 54 | `loadLocal()` |
| 67 | save book 0 title to `SharPreferences.selectedBook` |
| 73 | `deleteFiles` |
| 89 | do **not** call `clearAllData()` |
| 97 | toast `Updated Successfully`, `_invalidateHomeBibleMemoryCaches()`, `Get.offAll(HomeScreen(From: "splash", ...))` |

`_invalidateHomeBibleMemoryCaches()` clears `DashBoardController` verse/book caches and calls `DownloadProvider.clearInMemoryBibleCaches()` (`verse` lists, `book` lists, `BibleBookResolve.clearCache()`).

Onboarding (`from == 'onboard'`) still saves button states, then `CustomAlertBox` (which now skips the dialog), then `PreferenceSelectionScreen`.

Also call `LibraryVerseFlagsSync.reapplyToVerseTable()` at the end of `loadBookContent` in `preference_selection_screen.dart`.

`all-bible` has the sync class and never calls it. It also never calls `BibleBookResolve` outside the helper file.

---

## 4. Reading screen labels and one chapter

### `BibleUiLabels` — missing calls on `all-bible`

- Home `initState`: `await BibleUiLabels.refreshFromPrefs()`
- Chapter bar: `BibleUiLabels.chapterBarLabel(...)` → `Chapter - 3` or `Capítulo - 3`
- `chapterListScreen.dart` `initState`: `refreshFromPrefs()`
- Chapter list title word: `BibleUiLabels.chapterWordForDisplay(...)`

`all-bible` already has `BibleVersionConfig.chapterWord`. Point `refreshFromPrefs()` at that (`அதிகாரம்` for Tamil, `Chapter` for NLT) instead of the NKJV / Catholic switch.

### `DashBoardController` — missing on `all-bible`

- `syncSelectedBookTitleFromDb()` after both chapter-load paths, so the header is not stuck on the previous book name.
- When a book row is read (`id, chapter_count, read_per, title`), write `title` into `selectedBook` and prefs.
- `versesForUiChapterOnly(verses, uiChapter)` before painting Home, the audio button, and the quick chapter load (one `chapter_num` only).
- `_zeroBasedForUiChapterFilter`: unknown chapter basis defaults to 1-based (`?? false`).
- Font kept across controller rebuild: `static double? _persistedReadingFontSize` and `static String? _persistedReadingFontFamily` (tablet 25, phone 19, font `Arial`).

`_chapterLoadGeneration` and `displayBookReadPercent` are already on `all-bible`.

---

## 5. Daily Verse

Rule on `multi_screeen`: today and earlier dates keep the language they were stored in. Tomorrow onward follows the active Bible.

Missing call sites on `all-bible` (`download.notifier.dart`, `splash.dart`, `preference_selection_screen.dart`, `home_screen.dart`, `dailyverse.dart`):

- `_refreshFutureDailyVerseContentFromActiveBible`: rows dated after today get `verse.content` and the localized book title. Date, Book_Id, Chapter, and category stay.
- `_syncDailyVerseDisplayBookTitles()` after every Daily Verse list load.
- Topic rotation rebuild starts at **tomorrow**. Today’s rows stay.
- Book number comes from `BibleBookResolve.bookNumForDailyVerse(...)`, not `bookId - 1`.
- Stored `Book` is `localizedTitle ?? row['Book']`.
- First Daily Verse insert in `splash.dart` and `preference_selection_screen.dart` uses the same lookups.

---

## 6. Library marks (data stays; these calls are missing)

Do not add a `bible_folder` column. Do not delete library tables.

What `multi_screeen` does, and `all-bible` does not call:

1. After the verse table is rebuilt, `LibraryVerseFlagsSync.reapplyToVerseTable()` matches bookmark / highlight / underline / note text back onto the new verse ids. Rows are not deleted.
2. Bookmark, highlight, underline, and notes cards (list, grid, tablet) show `LibraryBibleVersionChip` before the reference. On `all-bible` the chip widget exists and is not placed on the cards. Chip label on this app should come from `BibleVersionConfig.chipLabel` for the active folders (`NLT`, `Tamil`), with the old text guess only as fallback.
3. Before Read from Library, Home, and Daily Verse: `LibraryBibleGuard.allowReadOrToast(...)`. On `multi_screeen` this **returns true** (the gate is off). `matchesCurrentBible()` is there for later.

The screenshot box in section 1.1 is the library-data change. Skipping that box and skipping `clearAllData()` is what keeps bookmarks, highlights, underlines, and notes.

---

## 7. Audio

`all-bible` already applies `BibleVersionConfig.audioBasePath` and `ttsLanguage` in `fActionButton.dart`. Do not replace that with the `multi_screeen` Portuguese / English-only helpers.

Empty `audioBasePath` on Tamil must keep falling through to the app audio base, the way it does now.

---

## Implement on `all-bible` in this order

1. Bible Version Continue: gray until Active, progress bar, no delete box, no `clearAllData`, no “A Beautiful Step Forward!” dialog, no rating prompt on this screen, `_runHomeBibleSwitchFlow`.
2. `LibraryVerseFlagsSync.reapplyToVerseTable()` after `loadBookContent` (switch + onboarding).
3. `BibleBookResolve` + future Daily Verse refresh (section 5).
4. `BibleUiLabels` + the controller title / one-chapter / font pieces in section 4.
5. Onboarding paywall: `folders.length > 1` → `FreeTrialIntroScreen` → `MultiSelectPaywall`; one folder → `SubscriptionScreen`. Fix `Cancel anytime`.
6. Restore / buy toasts in section 1.5.
7. Library chip on the four card layouts, and the guard call (still returns true).

## Check after the port

One folder: no Bible Version row, old `SubscriptionScreen`, no other change.

Two folders:

1. Onboarding: pick a Bible → preferences → ready → Free Trial Intro → multi paywall.
2. Continue on Bible Version stays gray until one Bible is **Active**, then the bar runs and Home reloads. The delete-library box does not appear. “A Beautiful Step Forward!” does not appear.
3. Bookmarks, highlights, underlines, and notes are still there after a switch, and still marked in the reader.
4. Header book name, chapter word, and a single chapter match the new Bible.
5. Today’s Daily Verse keeps its old language. Tomorrow follows the new Bible.
6. Restore with a purchase shows `Restore Successful` and does not follow it with `No purchases available to restore.`
