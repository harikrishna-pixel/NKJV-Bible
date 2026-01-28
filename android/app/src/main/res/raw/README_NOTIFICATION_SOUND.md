# Daily Verse Notification Bell Sound Setup

## ✅ Notification Sound is Already Configured in Code

The notification service (`lib/view/widget/notification_service.dart`) is already set up to play a bell sound for daily verse notifications:

- **Android**: Line 98 - `RawResourceAndroidNotificationSound('bell')`
- **iOS**: Line 101 - `sound: 'bell.caf'`

## 📁 Required Sound Files

### For Android:
Place a bell sound file in this folder with the name:
- **File**: `bell.mp3` or `bell.wav`
- **Location**: `android/app/src/main/res/raw/bell.mp3`

### For iOS:
Place a bell sound file with the name:
- **File**: `bell.caf` (iOS audio format)
- **Location**: `ios/Runner/bell.caf`

## 🔔 How to Add Bell Sound Files

### Option 1: Use Existing Asset Music
You have music in `assets/music/christian-rock-for-jesus-christ-always-301257.mp3`. However, for notifications:

1. **Convert to shorter bell sound** (3-5 seconds recommended for notification)
2. **For Android**: Copy/convert to `android/app/src/main/res/raw/bell.mp3`
3. **For iOS**: Convert to `.caf` format and place in `ios/Runner/bell.caf`

### Option 2: Download Free Bell Sound
1. Download a free bell sound from:
   - https://pixabay.com/sound-effects/search/bell/
   - https://freesound.org/search/?q=bell
2. Place in the locations mentioned above

### Convert to iOS .caf format:
```bash
# On Mac, use afconvert command:
afconvert -f caff -d LEI16 bell.mp3 bell.caf
```

## 🚀 After Adding Sound Files

1. **Clean and rebuild** your app:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

2. **Test the notification**:
   - Go to Settings → Notifications
   - Set a notification time
   - Wait for the notification to trigger
   - You should hear the bell sound!

## 📝 Note

**No code changes are needed** - the bell sound is already configured. You only need to add the actual sound files to the correct folders.
