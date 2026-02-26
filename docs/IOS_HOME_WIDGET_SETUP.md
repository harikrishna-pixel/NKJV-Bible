# iOS Home Screen Widget Setup (Xcode)

This app supports three **iOS-only** Home Screen widgets:

1. **Verse of the Day** – shows today’s verse (updated when daily verses load in the app).
2. **Bible Prayer** – opens Prayer Guidance when tapped.
3. **Bible Chat** – opens AI Bible Chat when tapped.

The following are **already done in code**:

- **Widget Extension target** `BibleHomeWidget` is added to the Xcode project.
- **Swift widget code** is in `ios/BibleHomeWidget/BibleHomeWidget.swift` (Verse of the Day, Bible Prayer, Bible Chat).
- **App Group** `group.com.balaklrapps.genevabible` is added to **Runner** (`Runner/Runner.entitlements`) and to **BibleHomeWidget** (`ios/BibleHomeWidget/BibleHomeWidget.entitlements`).
- Runner embeds the extension and has a dependency on BibleHomeWidget.

---

## 1. Open the iOS project in Xcode

```bash
cd ios
open Runner.xcworkspace
```

(Use `Runner.xcworkspace`, not `Runner.xcodeproj`.)

---

## 2. Build and run

1. Select the **Runner** scheme and an iOS device or simulator (iOS 14+).
2. Build and run (**⌘R**). The BibleHomeWidget extension will be built and embedded automatically.
3. On the device, long-press the home screen → **+** (Add Widget) → find **Verse of the Day**, **Bible Prayer**, and **Bible Chat** under your app → add them.

---

## 3. (Optional) Use a different App Group ID

If you prefer a different App Group (e.g. another team or identifier):

1. In Xcode, change the App Group for **Runner** and **BibleHomeWidget** to your new ID (e.g. `group.com.yourcompany.yourapp`).
2. In the Flutter project, open `lib/home_widget/bible_home_widget.dart` and set `_kAppGroupId` to the **same** string.
3. In the widget Swift file (inside the `BibleHomeWidget` target), set `appGroupId` at the top to the **same** string.

---

## 4. URL scheme (already configured)

The app is already set up to open when the user taps a widget:

- **Info.plist** has a URL type with scheme `biblebookapp`.
- The widget uses:
  - `biblebookapp://verse?homeWidget`
  - `biblebookapp://prayer?homeWidget`
  - `biblebookapp://chat?homeWidget`

The `homeWidget` query is required for the `home_widget` plugin to recognize the launch. No extra Xcode steps are needed for the scheme.

---

## Summary checklist

- [x] Widget Extension target **BibleHomeWidget** (added in `project.pbxproj`).
- [x] Widget Swift file at `ios/BibleHomeWidget/BibleHomeWidget.swift`.
- [x] **Runner** has **App Groups** in `Runner.entitlements` with `group.com.balaklrapps.genevabible`.
- [x] **BibleHomeWidget** has **App Groups** in `BibleHomeWidget.entitlements` with the same ID.
- [ ] Build Runner and add the three widgets from the home screen.

After this, opening the app and loading daily verses will update the **Verse of the Day** widget; tapping any of the three widgets will open the app to the correct screen (Verse of the Day, Prayer, or Chat).
