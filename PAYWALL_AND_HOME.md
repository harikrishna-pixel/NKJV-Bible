# Paywall UI + paywall logic + Home icons

Use this on the `all-bible` branch. Copy from `multi_screeen`. Do not replace unrelated files.

The earlier gap readme left `lib/view/screens/multi_select_paywall.dart` in place. That is why the paywall did not change. On `all-bible` that file is a different screen (about 2237 lines). The screen in the screenshot is `lib/view/screens/multi_select_paywallscreen.dart`.

Both files declare `class MultiSelectPaywall`. A file must import only one of them.

---

## 1. Paywall UI — copy this file

Copy `multi_screeen` → `all-bible`, same path:

`lib/view/screens/multi_select_paywallscreen.dart`

Assets that file already uses (they exist on both branches):

- `assets/img.png` — hero photo
- `assets/paywall_icons/premium.png` — crown badge, top left

Then point every screen that opens the paywall at **this** file:

| File on `all-bible` | Change the import to |
|---|---|
| `lib/view/screens/dashboard/home_screen.dart` | `multi_select_paywallscreen.dart` |
| `lib/view/screens/free_trial_intro_screen.dart` | `multi_select_paywallscreen.dart` |
| `lib/view/screens/free_trail_screen.dart` | `multi_select_paywallscreen.dart` |
| `lib/view/screens/paywall_navigation.dart` | `multi_select_paywallscreen.dart` |

`all-bible` `lib/main.dart` already imports `multi_select_paywallscreen.dart`. Leave that import. Do not also import `multi_select_paywall.dart` in the same file.

After the import change, Home Upgrade, Free Trial Continue, and `PaywallNavigation.buildVisiblePaywall` all build the screenshot screen.

### What the screen shows

Background cream `#F5EBD8`. Hero is `assets/img.png`.

- Top left: `assets/paywall_icons/premium.png`
- Top right: close (X)
- Title: **Grow Closer** / **to God Daily**. “God” and “Daily” are gold `#9E7340`. The rest is ink `#2D2D3A`. Phone title size 34, tablet 40, Georgia on tablet.
- Subtitle: “Guidance, prayer, and encouragement whenever you need it.”

Benefits card overlapping the hero:

| Icon | Title | Subtitle |
|---|---|---|
| heart | Pray With Confidence | Support in hard moments |
| book | Understand Scripture | God's Word made clear |
| heart | Find Peace Every Day | Hope when it's hard |

The benefit subtitle stays on one line (`FittedBox`).

**AI Premium** card, purple `#6D51A3`:

- Chips: **6 Months** (badge `SAVE 40%`) and **1 Year** (badge `POPULAR`)
- Default chip is **1 Year**
- Big price from the store, for example `$14.99/yr`, with a per-month line (`rawPrice / 6` or `rawPrice / 12`)
- Billing line: `billed yearly as $X · auto-renews` (6-month uses the 6-month price)
- Checklist: “Unlimited AI — chat, prayer & answers” and “Ad-free · all premium features”

**Lifetime** card is built (`_buildLifetimeCard`) and is **not** placed in the column. The lifetime product still loads.

Trust row: “Cancel anytime · Secure & trusted”.

Legal row, no underline: Terms of Use · Privacy Policy · Restore Purchases.

- Terms: `https://bibleoffice.com/terms_conditions.html`
- Privacy: `https://bibleoffice.com/privacy_policy.html`

Footer:

- Gold button `#B4842E → #C9A35A → #A9791F`
- Label: **Start 3-Day Free Trial ›** (lifetime selection would say **Get Lifetime Access ›**)
- “You won't be charged for the first 3 days”
- “then $X/yr · auto-renews · cancel anytime”
- **Continue with Limited Access**

Tablet (`width > 600`): side padding `(width * 0.08).clamp(36, 64)`, taller button, Georgia titles.

If the store price is missing, the fallbacks in the file are `$34.99` / `$59.99` / `$79.99`. The screenshot prices (`$14.99/yr`, `$1.50/mo`, `$1.25/mo`) are the store `ProductDetails.price`, not those fallbacks.

---

## 2. Paywall logic — inside `multi_select_paywallscreen.dart`

Do not add a second in-app purchase implementation. This screen only picks a plan and hands the buy to `SubscriptionScreen`.

### Products

```dart
var products = PaywallPreloadService.getPreloadedProducts();
if (products.isEmpty) {
  await PaywallPreloadService.preloadPaywallData();
  products = PaywallPreloadService.getPreloadedProducts();
}
```

Match a product when the id equals the resolved id, or the id contains `sixmonth`, `oneyear`, or `lifetime`. Never match an id that contains `exit`.

Resolved ids:

```dart
AppApiConstant.resolveSubscriptionProductId(widget.sixMonthPlan, BibleInfo.sixMonthPlanid);
AppApiConstant.resolveSubscriptionProductId(widget.oneYearPlan, BibleInfo.oneYearPlanid);
AppApiConstant.resolveSubscriptionProductId(widget.lifeTimePlan, BibleInfo.lifeTimePlanid);
```

Plan slot sent to the purchase host:

| Slot | Plan |
|---|---|
| 0 | 6 months |
| 1 | 1 year (default) |
| 2 | lifetime |

If the 1-year product is missing, the selection falls back to 6 months.

### Buy

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

### Restore

```dart
await SharPreferences.setBoolean('restorepurches', true);
await SharPreferences.setBoolean('startpurches', false);
// push SubscriptionScreen with invisiblePurchaseHost: true, autoStartRestore: true
// ok == true → refreshPremiumStatusFromPrefs() → navigateToStreakFlowOrHome
```

### Close and limited access

Close (X) and **Continue with Limited Access** both call `StreakFlowNavigation.navigateToStreakFlowOrHome`.

### Toasts on `SubscriptionScreen` (`intro_subcribtion_screen.dart`)

These strings are what the invisible host shows. `all-bible` still has the old ones unless they were already edited:

| Case | Text |
|---|---|
| Nothing to restore | `No purchases available to restore.` once |
| Restore worked | `Restore Successful` |
| Buy worked | `Purchase Successful` |

After `Restore Successful`, do not show the “no purchases” toast. If there is no internet during restore, close the invisible host.

`all-bible` already has `invisiblePurchaseHost`, `autoStartRestore`, `autoStartSelectedPlanPurchase`, and `_pendingBuyProductId`. Do not replace `intro_subcribtion_screen.dart`.

### When this screen opens

More than one folder (`BibleInfo.folders.length > 1`):

- Onboarding “ready” Continue → `FreeTrialIntroScreen` → its Continue opens `MultiSelectPaywall` from **paywallscreen**
- Home drawer Upgrade → `MultiSelectPaywall` from **paywallscreen**, `checkad: 'theme'`

One folder: keep `SubscriptionScreen` with `checkad: 'onboard'` or `'theme'`. Do not open this screen.

`paywallShows` on `all-bible` must not send onboarding to the old `multi_select_paywall.dart`. The folder check above is the route.

---

## 3. Home icons

The reading bar on `multi_screeen` shows, left to right after the book name: search, streak flame, theme moon.

`all-bible` still puts a Bible book image in that bar when `BibleInfo.folders.length != 1`:

```dart
Image.asset("assets/biblebook.png", ...)
```

That extra icon is what `multi_screeen` removed (“Bible Version moved to Settings”). It crowds the bar, so the flame or the moon does not show. Delete that `BibleVersionsScreen` / `biblebook.png` action from `home_screen.dart` `actions`.

The `actions` list must be only this:

```dart
actions: [
  Padding(
    padding: const EdgeInsets.only(right: 4),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () {
            if (controller.adFree.value == false) {
              controller.bannerAd?.dispose();
              controller.bannerAd?.load();
            }
            Get.to(
              () => SearchScreen(controller: controller),
              transition: Transition.cupertino,
              duration: const Duration(milliseconds: 300),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Image.asset(
              "assets/home icons/search.png",
              height: screenWidth > 450 ? 30 : 22,
              width: screenWidth > 450 ? 30 : 22,
              color: CommanColor.whiteBlack(context),
            ),
          ),
        ),
        const SizedBox(width: 6),
        StreakIconButton(
          iconSize: screenWidth > 450 ? 28 : 22,
        ),
        const SizedBox(width: 6),
        Padding(
          padding: const EdgeInsets.all(4),
          child: ChangeThemeButtonWidget(),
        ),
      ],
    ),
  ),
],
```

Search uses `CommanColor.whiteBlack(context)`, not `readerFg`. `readerFg` can match the paper and hide the icon.

`home_screen.dart` must import `package:biblebookapp/streak/streak_ui.dart` for `StreakIconButton`.

Theme moon is `ChangeThemeButtonWidget` in `lib/view/constants/changeThemeButtun.dart`:

- Light mode shows `assets/light_modes/Light mode.png`
- Dark mode shows `assets/dark_modes/Dark mode.png`

Flame is `StreakIconButton` in `lib/streak/streak_ui.dart`. On `all-bible` a pending streak (count showing, today not finished) paints the flame gray `#9E9E9E`. On `multi_screeen` that same state is orange `#E65100` at 55% opacity for the border, and the icon and number are `#E65100`. A finished day stays the filled orange badge `#E65100` with a white flame. The red dot is `#E53935`.

Bible Version stays in Settings and the drawer. It is not an icon on the reading bar.

---

## Check

1. Onboarding with two Bibles: Free Trial Intro, then the screenshot paywall (hero, AI Premium, 1 Year selected, gold trial button). Not the old paywall.
2. Prices come from the store. 6 Months and 1 Year both toggle. Lifetime card is not on screen.
3. Terms and Privacy open. Restore uses the invisible host.
4. Close and “Continue with Limited Access” leave the paywall.
5. Home reading bar shows search, orange flame, and the moon. The Bible book image is not in that bar.
