# Multi-Bible (Multi-Content) + Paywall — Porting Guide

This guide explains how to move **every multi-content, Library and paywall feature** from the
`multi_screeen` branch of this repo into another single ("individual") Bible app built on the
same codebase.

Reference repo: `NKJV-Bible`, branch `multi_screeen` (compare with `main`).
Rule used everywhere: **`BibleInfo.folders.length > 1` = multi-Bible mode.** With one folder, the
app behaves exactly like the old single-Bible app.

> Where this guide says "copy file", copy it as-is from this repo. Where it says "edit", apply only
> the described change — don't replace the whole target file.

---

## 0. Before you start (requirements in the target app)

The target app must already have these (they exist on `main` of this repo):

| Needed | Where |
|---|---|
| `SubscriptionScreen` with `invisiblePurchaseHost`, `autoStartSelectedPlanPurchase`, `initialSelectedPlanIndex` | `lib/view/screens/intro_subcribtion_screen.dart` |
| `DashBoardController.refreshPremiumStatusFromPrefs()` | `lib/controller/dashboard_controller.dart` |
| `PaywallPreloadService` | `lib/services/paywall_preload_service.dart` |
| `AppApiConstant.resolveSubscriptionProductId` | `lib/constant/app_api_constant.dart` |
| `StreakFlowNavigation.navigateToStreakFlowOrHome` | `lib/streak_flow/streak_flow_screens.dart` |
| `DBHelper` with `updateVersesDataByContent`, `updateVersesDataByContentnew`, `updateVersesDataByContentnewcheck`, `getBookMark/getHighlight/getUnderLine/getNotes` | `lib/controller/dpProvider.dart` |
| `BibleVersionsScreen` (`bible_select_screen.dart`) with `buttonStates` saved in prefs as `"folder:DownloadButtonState.active"` | `lib/view/screens/bible_select_screen.dart` |
| `FreeTrialIntroScreen` | `lib/view/screens/free_trial_intro_screen.dart` |

If the target app is older and lacks any of these, port them first from `main`.

---

## 1. Content setup (multiple Bibles)

### 1.1 `BibleInfo.folders` — `lib/view/screens/dashboard/constants.dart` (edit)

```dart
// add folder names here  assets/zipped/
static List<String> folders = [
  "NKJV",
  "catholic",
  // add up to 7: "KJV", "NIV", "spanish_rvr", ...
];
```

### 1.2 Assets — `pubspec.yaml` (edit)

Each folder needs `book.json.zip` and `verse_json.zip` (same password as today,
`dotenv.env[AssetsConstants.holybibleKey]`):

```yaml
flutter:
  assets:
    - assets/zipped/
    - assets/zipped/NKJV/
    - assets/zipped/catholic/
    # one line per extra folder
```

### 1.3 Per-Bible config (NEW — required for more than NKJV + Catholic)

In this repo, six places are hardcoded to NKJV (English) / Catholic (Portuguese). For 3–7 Bibles
create **one config file** and make those six places read from it (see section 9).

Create `lib/utils/bible_version_config.dart`:

```dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';

class BibleVersionConfig {
  const BibleVersionConfig({
    required this.folder,
    required this.displayName,
    required this.chipLabel,
    required this.languageCode,
    required this.chapterWord,
    required this.ttsLanguage,
    required this.audioBasePath,
    this.otBookCount = 39,
    this.bookAliases = const {},
  });

  final String folder;          // must equal the BibleInfo.folders entry
  final String displayName;     // Bible Version screen, e.g. "Catholic Bible"
  final String chipLabel;       // Library chip, e.g. "Catholic"
  final String languageCode;    // "en", "pt", "es", "hi"...
  final String chapterWord;     // "Chapter", "Capítulo", "Capítulo", "अध्याय"
  final String ttsLanguage;     // "en-US", "pt-BR", "es-ES"...
  final String audioBasePath;   // mp3 base, '<base>/<bookNum>/<chapterNum>.mp3'
  final int otBookCount;        // 39 Protestant, 46 Catholic
  /// English book name (lowercase) -> extra local names (lowercase, accents removed).
  final Map<String, List<String>> bookAliases;

  static const all = <BibleVersionConfig>[
    BibleVersionConfig(
      folder: 'NKJV',
      displayName: 'NKJV Bible',
      chipLabel: 'NKJV',
      languageCode: 'en',
      chapterWord: 'Chapter',
      ttsLanguage: 'en-US',
      audioBasePath:
          'https://bibleoffice.com/BibleReplications/dev/v1/uploads/bible_audio/English',
    ),
    BibleVersionConfig(
      folder: 'catholic',
      displayName: 'Catholic Bible',
      chipLabel: 'Catholic',
      languageCode: 'pt',
      chapterWord: 'Capítulo',
      ttsLanguage: 'pt-BR',
      audioBasePath:
          'https://bibleoffice.com/BibleReplications/dev/v1/uploads/bible_audio/Portuguese',
      otBookCount: 46,
    ),
    // add the other versions here
  ];

  static BibleVersionConfig? forFolder(String? folder) {
    if (folder == null) return null;
    for (final c in all) {
      if (c.folder.toLowerCase() == folder.toLowerCase()) return c;
    }
    return null;
  }

  /// Active folder from Bible Version selection (`buttonStates` pref).
  static Future<String?> activeFolder() async {
    final prefs = await SharedPreferences.getInstance();
    for (final entry in prefs.getStringList('buttonStates') ?? const []) {
      final parts = entry.split(':');
      if (parts.length == 2 && parts[1].contains('DownloadButtonState.active')) {
        return parts[0];
      }
    }
    return BibleInfo.folders.length == 1 ? BibleInfo.folders.first : null;
  }

  static Future<BibleVersionConfig?> active() async =>
      forFolder(await activeFolder());
}
```

---

## 2. Multi-select paywall (content paywall UI)

### 2.1 Copy file

`lib/view/screens/multi_select_paywallscreen.dart` → same path.
(`multi_select_paywall.dart` is an older duplicate with the same class name — **copy only one**.
If both exist, keep `multi_select_paywallscreen.dart` and point every import to it.)

### 2.2 What the screen contains

- **Hero:** background `assets/img.png` (phone: `BoxFit.cover` + light wash; tablet: `fitWidth`),
  `assets/paywall_icons/premium.png` top-left, close (X) button top-right.
  Title "Grow Closer / to **God Daily**" (gold `#9E7340`), subtitle
  "Guidance, prayer, and encouragement whenever you need it."
- **Benefits card** overlapping the hero: *Pray With Confidence*, *Understand Scripture*,
  *Find Peace Every Day* (the subtitle uses `FittedBox` so it stays on one line).
- **AI Premium card** (purple `#6D51A3`): 6 Months / 1 Year chips (badges `SAVE 40%` / `POPULAR`),
  price with per-month value, billing note, and checklist rows:
  "Unlimited AI — chat, prayer & answers", "Ad-free · all premium features".
- **Lifetime card:** built (`_buildLifetimeCard`) but **hidden in the UI**. Its product still
  loads and can still be bought, so you can show it again by adding it back to the `Column`.
- **Trust row:** "Cancel anytime · Secure & trusted".
- **Legal row:** Terms of Use · Privacy Policy · Restore Purchases (no underline).
- **Footer:** gold gradient CTA "Start 3-Day Free Trial ›" (or "Get Lifetime Access ›"),
  trust line, micro-copy "then $X/yr · auto-renews · cancel anytime", and
  "Continue with Limited Access".
- **Tablet (width > 600):** side padding `(w * 0.08).clamp(36, 64)`, bigger fonts, Georgia titles.

Change the legal URLs (`bibleoffice.com/terms_conditions.html`, `privacy_policy.html`) if the
target app uses different ones.

### 2.3 Paywall logic (inside the file)

**Products** — same source as `SubscriptionScreen`:

```dart
var products = PaywallPreloadService.getPreloadedProducts();
if (products.isEmpty) {
  await PaywallPreloadService.preloadPaywallData();
  products = PaywallPreloadService.getPreloadedProducts();
}
// match by resolved id OR id contains 'sixmonth' / 'oneyear' / 'lifetime' (never 'exit')
```

Resolved ids:

```dart
AppApiConstant.resolveSubscriptionProductId(widget.sixMonthPlan, BibleInfo.sixMonthPlanid);
AppApiConstant.resolveSubscriptionProductId(widget.oneYearPlan,  BibleInfo.oneYearPlanid);
AppApiConstant.resolveSubscriptionProductId(widget.lifeTimePlan, BibleInfo.lifeTimePlanid);
```

- The default selection is **1 Year**. If the 1-year product is missing, it falls back to 6 months.
- Prices come from the store (`ProductDetails.price`), with fallbacks `$34.99` / `$59.99` / `$79.99`.
- Per-month price = `rawPrice / 6` or `rawPrice / 12`.

**Plan slot** passed to the purchase host: `0 = 6 months`, `1 = 1 year`, `2 = lifetime`.

**Buy** — no duplicate in-app purchase code. It pushes a transparent `SubscriptionScreen` that buys
immediately:

```dart
Future<void> _startPurchase() async {
  if (!await SubscriptionScreen.isDashboardIapEnabled()) return;
  final ok = await Navigator.of(context).push<bool>(PageRouteBuilder<bool>(
    opaque: false,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    pageBuilder: (ctx, _, __) => SubscriptionScreen(
      sixMonthPlan: widget.sixMonthPlan,
      oneYearPlan: widget.oneYearPlan,
      lifeTimePlan: widget.lifeTimePlan,
      checkad: widget.checkad,
      initialSelectedPlanIndex: _selectedPlanSlot,
      autoStartSelectedPlanPurchase: true,
      invisiblePurchaseHost: true,
    ),
  ));
  if (ok == true && mounted) {
    if (Get.isRegistered<DashBoardController>()) {
      await Get.find<DashBoardController>().refreshPremiumStatusFromPrefs();
    }
    await StreakFlowNavigation.navigateToStreakFlowOrHome(context);
  }
}
```

**Restore** — same pattern, with the flags set first:

```dart
await SharPreferences.setBoolean('restorepurches', true);
await SharPreferences.setBoolean('startpurches', false);
// push SubscriptionScreen(... invisiblePurchaseHost: true, autoStartRestore: true)
// on ok == true -> refreshPremiumStatusFromPrefs() -> navigateToStreakFlowOrHome
```

**Close / Continue with Limited Access** → `StreakFlowNavigation.navigateToStreakFlowOrHome(context)`.

---

## 3. `SubscriptionScreen` changes (edit `intro_subcribtion_screen.dart`)

These make the invisible host work for Restore and fix the iOS restore/buy bugs.

### 3.1 New widget flag

```dart
/// Transparent host: auto-run Restore (same `_restorePurchases` path) without
/// showing the single-version paywall UI (MultiSelect Restore).
final bool autoStartRestore;          // constructor: this.autoStartRestore = false
```

### 3.2 New state fields

```dart
String? _pendingBuyProductId;         // product the user tapped Buy on
bool _autoRestoreTriggered = false;
bool _restoreSuccessToastShown = false;
```

In `_buyProduct(prod)`, set `_pendingBuyProductId = prod.id;` before calling the store.

### 3.3 Auto restore (call after `_autoStartPurchaseIfNeeded()` in the initialise method)

```dart
Future<void> _autoStartRestoreIfNeeded() async {
  if (!widget.autoStartRestore || _autoRestoreTriggered) return;
  if (!widget.invisiblePurchaseHost) return;
  _autoRestoreTriggered = true;
  await SharPreferences.setString('OpenAd', '1');
  await SharPreferences.setBoolean('restorepurches', true);
  await SharPreferences.setBoolean('startpurches', false);
  await _restorePurchases(controller);
}

// in initialise:
await _autoStartPurchaseIfNeeded();
await _autoStartRestoreIfNeeded();
```

### 3.4 iOS "restored" during Buy (in `_listenToPurchaseUpdated`)

iOS often reports a successful Buy as `restored`. Treat it as a purchase **only for the tapped
product**, so an old Lifetime receipt doesn't overwrite a new 6-month/1-year plan:

```dart
final startFlagForBuy = await SharPreferences.getBoolean('startpurches');
final restoreFlagForBuy = await SharPreferences.getBoolean('restorepurches');
final isBuyReportedAsRestored =
    purchaseDetails.status == PurchaseStatus.restored &&
    startFlagForBuy == true &&
    restoreFlagForBuy != true &&
    _pendingBuyProductId != null &&
    purchaseDetails.productID == _pendingBuyProductId;

if (purchaseDetails.status == PurchaseStatus.purchased || isBuyReportedAsRestored) {
  // existing purchase-success branch (unchanged)
} else {
  final restoreFlag = await SharPreferences.getBoolean('restorepurches');
  // Restore only when the user tapped Restore.
  if (restoreFlag == true) {
    if (_shouldShowRestoreDialog &&
        _pendingRestoreProductId == purchaseDetails.productID) {
      if (mounted) await _showRestoreDialogForRestoredPurchase(purchaseDetails, controller);
      _shouldShowRestoreDialog = false;
      _pendingRestoreProductId = null;
    } else if (mounted) {
      _handleRestore(purchaseDetails, controller);
    }
  } else if (purchaseDetails.pendingCompletePurchase) {
    await InAppPurchase.instance.completePurchase(purchaseDetails);
  }
}
```

Remove the old `startFlag == true` → restore branch.

### 3.5 Toast gating

```dart
void _showNoPurchasesToRestoreToast([DashBoardController? controller]) {
  if (_restoreSuccessToastShown) return;
  final c = controller ??
      (Get.isRegistered<DashBoardController>() ? Get.find<DashBoardController>() : null);
  if (c != null && c.adFree.value == true) return;
  Constants.showToast('No purchases available to restore.');
}

Future<void> _showRestoreOrPurchaseSuccessToast(String message) async {
  if (message == 'Restore Successful') _restoreSuccessToastShown = true;
  if (message == 'Restore Successful' || message == 'Purchase Successful') {
    Constants.showToast(message, 2500);
    await Future<void>.delayed(const Duration(milliseconds: 2200));
    return;
  }
  Constants.showToast(message);
}
```

- Replace every `Constants.showToast('No active subscription available')` with
  `_showNoPurchasesToRestoreToast(controller)`.
- Replace every `Constants.showToast('Purchase Successful' / 'Restore Successful')` with
  `await _showRestoreOrPurchaseSuccessToast(...)`.
- Reset `_restoreSuccessToastShown = false` when a restore session starts.

### 3.6 Close the invisible host on failure

Wherever restore stops early (no internet, or an exception), add:

```dart
if (widget.invisiblePurchaseHost) _popInvisiblePurchaseHost(false);
```

---

## 4. Paywall routing (single vs multi)

### 4.1 Onboarding — `preference_selection_screen.dart` (edit)

On "Your Bible experience is ready" → Continue (when internet and product data are available):

```dart
final sixMonthPlan = BibleInfo.sixMonthPlanid;
final oneYearPlan = BibleInfo.oneYearPlanid;
final lifeTimePlan = BibleInfo.lifeTimePlanid;
if (BibleInfo.folders.length > 1) {
  Get.offAll(() => FreeTrialIntroScreen(
        sixMonthPlan: sixMonthPlan, oneYearPlan: oneYearPlan, lifeTimePlan: lifeTimePlan),
      transition: SubscriptionScreen.paywallRouteTransition,
      duration: SubscriptionScreen.paywallRouteDuration);
} else {
  Get.offAll(() => SubscriptionScreen(
        sixMonthPlan: sixMonthPlan, oneYearPlan: oneYearPlan,
        lifeTimePlan: lifeTimePlan, checkad: 'onboard'),
      transition: SubscriptionScreen.paywallRouteTransition,
      duration: SubscriptionScreen.paywallRouteDuration);
}
```

`FreeTrialIntroScreen` / `FreeTrailScreen` "Continue" → `MultiSelectPaywall(...)`.
Also fix the typo in both: `'Cancel \ngitanytime'` → `'Cancel \nanytime'`.

The "ready" screen label uses `PreferenceSelectionScreen.formatSelectedTopicsLabel(topics)`.

### 4.2 Home drawer Upgrade — `home_screen.dart` (edit `openPaywallFromDrawer`)

```dart
if (BibleInfo.folders.length > 1) {
  Get.to(() => MultiSelectPaywall(
        sixMonthPlan: sixMonthPlan, oneYearPlan: oneYearPlan,
        lifeTimePlan: lifeTimePlan, checkad: 'theme'),
      transition: SubscriptionScreen.paywallRouteTransition,
      duration: SubscriptionScreen.paywallRouteDuration);
} else {
  SubscriptionScreen.openPaywallStacked(
      sixMonthPlan: sixMonthPlan, oneYearPlan: oneYearPlan,
      lifeTimePlan: lifeTimePlan, checkad: 'theme');
}
```

The Upgrade banner shows when `(controller.isSubscriptionEnabled ?? false) && !controller.adFree.value`.

---

## 5. Bible Version switching

### 5.1 Entry points (edit)

- **Settings** (`setting_screen.dart`): a row shown only when `BibleInfo.folders.length > 1`:
  ```dart
  if (BibleInfo.folders.length > 1)
    InkWell(onTap: () => Get.to(() => const BibleVersionsScreen(from: 'home'),
        transition: Transition.cupertinoDialog,
        duration: const Duration(milliseconds: 300)),
      child: /* icon + "Bible Version" */),
  ```
- **Drawer** (`ios_style_app_drawer.dart`): new params
  `final bool showBibleVersion; final VoidCallback? onBibleVersionTap;` and an item
  `'Bible Version'` rendered when `showBibleVersion && onBibleVersionTap != null`.
  Home passes `showBibleVersion: BibleInfo.folders.length > 1` and opens
  `BibleVersionsScreen(from: 'home')`.
- The old Bible Version entry on Home was removed ("moved to Settings").

### 5.2 `BibleVersionsScreen` UI (edit `bible_select_screen.dart`)

- The list is built from `BibleInfo.folders` (already generic).
- Display name → use the config: `BibleVersionConfig.forFolder(folder)?.displayName ?? folder`
  (replaces `_bibleDisplayName` switch).
- **Continue button** is gray (`#B8B0A6`) until a Bible is set as primary:
  ```dart
  final hasPrimarySelected =
      buttonStates.values.any((s) => s == DownloadButtonState.active);
  ```
- While switching, show `_bibleSwitchProgressBar(isTablet)` **above** the button: a rounded bar
  with a gold gradient fill (`#D4A04A → #C59434 → #9A6B2F`) and a white `NN%` label (Georgia).
- Double-tap guard: `if (isloading == true) return;`
- **No confirm popup** when switching from Home (the old `showClearDatabaseDialog` was removed).
- The rating prompt was removed from this screen.
- Onboarding (`from == 'onboard'`): `_saveButtonStates()` → `CustomAlertBox` →
  `PreferenceSelectionScreen(isSetting: false, selectedbible: foldername)` (unchanged).

### 5.3 Switch flow (Home) — `_runHomeBibleSwitchFlow()`

Order and progress values:

| % | Step |
|---|---|
| 5 | `extractFromFolder(folderName, password: dotenv.env[AssetsConstants.holybibleKey], from: "home")` |
| 15 | `loadBookContent(foldername)` — rebuilds the `verse` table, **then calls `LibraryVerseFlagsSync.reapplyToVerseTable()`** |
| 27 | `loadBookList(foldername)` |
| 43 | `_savePreferences()` |
| 54 | `loadLocal()` |
| 67 | save `book_num = 0` title to `SharPreferences.selectedBook` |
| 73 | `deleteFiles(foldername)` |
| 89 | **do NOT call `clearAllData()`**; Library data is kept across switches |
| 97 | toast "Updated Successfully" → `_invalidateHomeBibleMemoryCaches()` → `Get.offAll(HomeScreen(From: "splash", ...))` |

```dart
Future<void> _invalidateHomeBibleMemoryCaches() async {
  try {
    if (Get.isRegistered<DashBoardController>()) {
      final c = Get.find<DashBoardController>();
      c.selectedBookContent.clear();
      c.selectedVersesContent.clear();
      c.isFetchContent.value = true;
      c.loadTextToSpeech.value = true;
    }
  } catch (_) {}
  if (!mounted) return;
  try {
    Provider.of<DownloadProvider>(context, listen: false).clearInMemoryBibleCaches();
  } catch (_) {}
}
```

Add to `DownloadProvider` (`download.notifier.dart`):

```dart
void clearInMemoryBibleCaches() {
  verseList = []; otVerseList = []; ntVerseList = [];
  bookList = []; otBookList = []; ntBookList = [];
  BibleBookResolve.clearCache();
  notifyListeners();
}
```

Also call `LibraryVerseFlagsSync.reapplyToVerseTable()` at the end of `loadBookContent` in
`preference_selection_screen.dart` (onboarding path).

---

## 6. Library (Bookmarks, Highlights, Underlines, Notes)

### 6.1 Copy files

- `lib/utils/library_verse_flags_sync.dart`
- `lib/utils/library_bible_guard.dart`
- `lib/utils/library_bible_version_tag.dart` (then make it generic, see 6.4)

### 6.2 Keep Library marks after a switch — `LibraryVerseFlagsSync`

After the `verse` table is rebuilt, verse ids change. `reapplyToVerseTable()` re-applies the flags
by **content match**:

| Library list | verse column | value |
|---|---|---|
| `getBookMark()` | `is_bookmarked` | `yes` |
| `getHighlight()` | `is_highlighted` | `${e.color}` (uses `updateVersesDataByContentnewcheck`) |
| `getUnderLine()` | `is_underlined` | `yes` |
| `getNotes()` | `is_noted` | `${e.notes}` |

It matches on both plain text (HTML stripped) and raw content. Library rows are never deleted.

### 6.3 Version chip on every Library card

In **bookMarkScreen, highlight_screen, underLine_screen, notes_screen**, add the chip in all three
card layouts (list, grid, tablet) before the reference text:

```dart
Row(children: [
  LibraryBibleVersionChip(
    bookName: data.bookName,
    content: data.content ?? data.plaincontent,
  ),
  const Spacer(),
  Text("${data.bookName} ${data.chapterNum}:${data.verseNum}"),
]),
```

Chip style: padding 8×3, radius 10, font 10 w700, border `lightDarkPrimary @ 35%`,
background `#E8F0E6` (Catholic) / `#F3EADF` (others).

### 6.4 Make the chip work for 7 Bibles

Today `libraryBibleVersionLabel()` guesses from the text: "Catholic" if it looks Portuguese,
otherwise "NKJV". For more versions, **save the folder with each item** and read it back:

1. Add a nullable `bible_folder TEXT` column to the bookmark / highlight / underline / notes tables
   (DB migration: `ALTER TABLE ... ADD COLUMN bible_folder TEXT`).
2. When saving an item, store `await BibleVersionConfig.activeFolder()`.
3. Chip label:
   ```dart
   BibleVersionConfig.forFolder(item.bibleFolder)?.chipLabel
       ?? libraryBibleVersionLabel(bookName: ..., content: ...) // old items fallback
   ```

### 6.5 Library → Read guard — `LibraryBibleGuard`

Call it before navigating to Read from Library, Home and Daily Verse:

```dart
final canRead = await LibraryBibleGuard.allowReadOrToast(
  bookNum: data.bookNum,
  chapterNum: data.chapterNum,
  verseNum: data.verseNum,
  savedContent: data.content ?? data.plaincontent,
);
if (!canRead) return;
```

- `allowReadOrToast` **currently always returns true**, so the gate is disabled on purpose.
- `matchesCurrentBible()` is ready: it looks up the verse (tries 0-based and 1-based chapter and
  verse) and compares the text.
- To enable the gate, return `matchesCurrentBible(...)` and show
  `LibraryBibleGuard.differentBibleMessage` when it doesn't match.

---

## 7. Book names and labels across Bibles

### 7.1 Copy `lib/utils/bible_book_resolve.dart` — `BibleBookResolve`

- `bookNumForDailyVerse(bookName, bookId, db)`: matches the book **by name** against
  `book.title / short_title / ntitle` (accent-folded). Falls back to `Book_Id - 1`.
- `titleForBookNum(bookNum)`: the localized title from the active Bible.
- `lookupVerseRowsForDailyMain(...)` and `dailyVerseDbChapterVerse(...)`: convert to the
  verse table's 0-based indices.
- `clearCache()`: call after every Bible switch (done in `clearInMemoryBibleCaches`).
- **For extra languages**, merge `BibleVersionConfig.bookAliases` into `_englishAliases`
  (for example Spanish `'john': ['juan']`).

Used in: `splash.dart`, `preference_selection_screen.dart`, `home_screen.dart`, `dailyverse.dart`,
`download.notifier.dart`, `bible_select_screen.dart`.

### 7.2 Copy `lib/utils/bible_ui_labels.dart` — `BibleUiLabels`

- `refreshFromPrefs()`: call in Home `initState` and `ChapterListScreen` `initState`.
- Home chapter bar: `BibleUiLabels.chapterBarLabel(chapterNum: ..., bookTitle: ...)` →
  "Chapter - 3" / "Capítulo - 3".
- Chapter list: `BibleUiLabels.chapterWordForDisplay(bookTitle: ...)`.
- **For 7 Bibles:** in `refreshFromPrefs()` set
  `_chapterWord = BibleVersionConfig.forFolder(folder)?.chapterWord ?? 'Chapter';`
  and make `chapterWordForDisplay` return `_chapterWord`.

### 7.3 Old/New Testament split — `book_list_screen.dart` (edit)

```dart
void _splitTestaments() {
  const ntBookCount = 27;
  if (bookList.length >= BibleInfo.old_testament_count + ntBookCount) {
    testament_num = bookList.length - ntBookCount;   // Catholic 73 → OT 46
  } else {
    testament_num = BibleInfo.old_testament_count;
  }
  // books with bookNum >= testament_num go to the New Testament list
}
```

This works for any Bible whose last 27 books are the New Testament.

### 7.4 `DashBoardController` display fixes (edit)

- `syncSelectedBookTitleFromDb()`: reads `SELECT title FROM book WHERE book_num = ?` and updates
  `selectedBook` + prefs. Call it after the chapter load finishes (both load paths), so the header
  isn't stuck on "Genesis" after a switch.
- Wherever a book row is read (`id, chapter_count, read_per, title`), also sync the `title`.
- `versesForUiChapterOnly(verses, uiChapter)`: keeps exactly one `chapter_num` (removes accidental
  N + N+1 merges). Apply it to every list before painting (Home reader, audio button, quick chapter
  load).
- `_zeroBasedForUiChapterFilter(...)`: when the chapter basis is unknown, the default is now 1-based
  (`?? false`, was `?? true`).
- `_chapterLoadGeneration` load id: cancels older chapter loads so a slow load can't overwrite
  the new chapter.
- Font persistence across controller re-creation:
  `static double? _persistedReadingFontSize; static String? _persistedReadingFontFamily;`
  (default 25 on tablet, 19 on phone, font 'Arial').
- `static int displayBookReadPercent(String? readPer)`: rounds the stored percentage for the UI.

---

## 8. Daily Verse in multi-Bible mode (`download.notifier.dart`, edit)

Rule: **past and today keep the language they were stored in; tomorrow onward follows the active Bible.**

- `_refreshFutureDailyVerseContentFromActiveBible(db)`: for rows dated after today, re-reads
  `verse.content` (0-based chapter/verse) and the localized `Book` title, then
  `UPDATE dailyVersesnew SET Verse = ?, Book = ? WHERE id = ?`. Date, Book_Id, Chapter and category
  never change.
- `_syncDailyVerseDisplayBookTitles()`: the same rule for the in-memory `dailyVerseList`. Call it
  after every Daily Verse list load.
- Rebuilding the topic rotation now starts from **tomorrow** (`startDate: tomorrow`), and today's
  rows are kept.
- Every place that did `bookNum = bookId - 1` now uses `BibleBookResolve.bookNumForDailyVerse(...)`,
  and stores `Book: localizedTitle ?? row['Book']`.
- Apply the same `BibleBookResolve` lookups in `splash.dart` and
  `preference_selection_screen.dart` where the first Daily Verse is inserted.

---

## 9. Audio and text-to-speech per Bible (`fActionButton.dart`, edit)

Current code (two languages):

```dart
Future<String?> _activeBibleFolder()          // reads buttonStates
bool _folderIsPortuguese(String? folder)       // catholic / portug / pt / almeida
String _audioBasePathForFolder(String? folder) // Portuguese or English mp3 base
Future<String> _buildVersionAudioUrl({bookNum, chapterNum}) // '$base/$book/$chapter.mp3'
Future<void> _applyTtsLanguageForActiveBible() // pt-BR or API/English
```

Call `_applyTtsLanguageForActiveBible()` after TTS init and before speaking.

**Generic version for 7 Bibles:**

```dart
Future<String> _resolvedAudioBasePath() async {
  final cfg = await BibleVersionConfig.active();
  return (cfg?.audioBasePath ??
          widget.audioData?.data?.bibleAudioInfo?.audioBasepath ??
          BibleInfo.audioBasePath)
      .replaceAll(RegExp(r'/+$'), '');
}

Future<void> _applyTtsLanguageForActiveBible() async {
  if (!_isTtsInitialized) return;
  final cfg = await BibleVersionConfig.active();
  final lang = cfg?.ttsLanguage ??
      widget.audioData?.data?.bibleAudioInfo?.textToSpeechLanguageCodeIos ??
      BibleInfo.textToSpeechLanguageCodeIos;
  if (lang.isEmpty) return;
  language = lang;
  await flutterTts.setLanguage(lang);
}
```

---

## 10. Hardcoded places to replace for 3–7 Bibles (summary)

| # | File | Today | Change to |
|---|---|---|---|
| 1 | `bible_select_screen.dart` `_bibleDisplayName` | NKJV / catholic only | `BibleVersionConfig.forFolder(f)?.displayName ?? f` |
| 2 | `library_bible_version_tag.dart` | guesses NKJV / Catholic | saved `bible_folder` → `chipLabel` (6.4) |
| 3 | `bible_ui_labels.dart` | Chapter / Capítulo | `config.chapterWord` (7.2) |
| 4 | `bible_book_resolve.dart` `_englishAliases` | English + Portuguese | add `config.bookAliases` (7.1) |
| 5 | `fActionButton.dart` audio / TTS | English / Portuguese | `config.audioBasePath` / `config.ttsLanguage` (9) |
| 6 | `book_list_screen.dart` | last 27 = NT | OK if canon ends with the 27 NT books; otherwise use `config.otBookCount` |

---

## 11. Files checklist

**Copy (new):**

- `lib/view/screens/multi_select_paywallscreen.dart`
- `lib/utils/bible_book_resolve.dart`
- `lib/utils/bible_ui_labels.dart`
- `lib/utils/library_bible_guard.dart`
- `lib/utils/library_bible_version_tag.dart`
- `lib/utils/library_verse_flags_sync.dart`
- `lib/utils/bible_version_config.dart` (new from section 1.3)

**Edit:**

- `lib/view/screens/dashboard/constants.dart`: folders
- `pubspec.yaml`: `assets/zipped/<folder>/`
- `lib/view/screens/intro_subcribtion_screen.dart`: section 3
- `lib/view/screens/free_trial_intro_screen.dart`, `free_trail_screen.dart`: open `MultiSelectPaywall`, typo fix
- `lib/view/screens/dashboard/preference_selection_screen.dart`: routing, flags sync, Daily Verse resolve
- `lib/view/screens/dashboard/home_screen.dart`: drawer paywall routing, Bible Version drawer item, chapter label, guard, font, one-chapter guard
- `lib/view/screens/dashboard/ios_style_app_drawer.dart`: `showBibleVersion` / `onBibleVersionTap`
- `lib/view/screens/dashboard/setting_screen.dart`: Bible Version row
- `lib/view/screens/bible_select_screen.dart`: section 5
- `lib/view/screens/dashboard/bookMarkScreen.dart`, `highlight_screen.dart`, `underLine_screen.dart`, `notes_screen.dart`: chip and guard
- `lib/view/screens/dashboard/book_list_screen.dart`: testament split
- `lib/view/screens/dashboard/chapterListScreen.dart`: chapter word
- `lib/view/screens/dashboard/dailyverse.dart`: resolve and guard
- `lib/view/screens/dashboard/fActionButton.dart`: audio and TTS
- `lib/controller/dashboard_controller.dart`: section 7.4
- `lib/core/notifiers/download.notifier.dart`: `clearInMemoryBibleCaches`, section 8
- `lib/view/screens/auth/splash.dart`: Daily Verse resolve

**Assets:** `assets/img.png`, `assets/paywall_icons/premium.png` (plus the zipped Bible folders).

**Suggested order:** 1 → 7.1 / 7.2 → 6 → 5 → 7.3 / 7.4 → 8 → 9 → 3 → 2 → 4.

---

## 12. Test checklist

**Single-Bible build (`folders.length == 1`):** no Bible Version entry, the old `SubscriptionScreen`
everywhere, and no behaviour change.

**Multi-Bible build:**

1. Onboarding: select a Bible → preferences → "ready" → Free Trial Intro → Multi-select paywall.
2. Paywall: prices load, 6-month / 1-year toggle, CTA text changes, tablet layout, Terms/Privacy open.
3. Buy 1 year and buy 6 months → premium active → Home. (iOS) Buying when a Lifetime receipt
   exists doesn't change the plan to Lifetime.
4. Restore with a purchase → "Restore Successful" (no "No purchases" toast after it). Restore with
   no purchase → "No purchases available to restore." once. No internet → host closes.
5. Close / "Continue with Limited Access" → streak flow or Home.
6. Settings → Bible Version and Drawer → Bible Version open the screen. Continue is gray until
   one is set as primary, the progress bar goes 5% → 97%, then Home reloads the new Bible.
7. After a switch: header book name, the Chapter/Capítulo word, the OT/NT split, and exactly one
   chapter showing.
8. Library: bookmarks, highlights, underlines and notes still exist after switching, and are still
   marked in the reader. Every card shows the correct version chip.
9. Library → Read works (guard disabled). If you enable the guard, the toast shows for another
   Bible's items.
10. Daily Verse: today's verse keeps its language after a switch; tomorrow's follows the new Bible.
11. Audio and TTS play in the active Bible's language.
12. Switch back and forth across all 7 Bibles with no crash and no stale verses.
