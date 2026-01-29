#!/bin/bash

# Fix Notification Bell Sound - Trim to 3 seconds
# This script creates a shorter version of the bell sound suitable for notifications

echo "🔔 Fixing Daily Verse Notification Bell Sound..."
echo ""

# Check if ffmpeg is installed
if ! command -v ffmpeg &> /dev/null; then
    echo "❌ ffmpeg is not installed."
    echo ""
    echo "Please install ffmpeg first:"
    echo "  macOS: brew install ffmpeg"
    echo "  Ubuntu: sudo apt install ffmpeg"
    echo ""
    exit 1
fi

# Backup original files
echo "📦 Backing up original files..."
cp android/app/src/main/res/raw/bell.mp3 android/app/src/main/res/raw/bell_original.mp3.bak
cp ios/Runner/bell.mp3 ios/Runner/bell_original.mp3.bak

# Create 3-second version for Android
echo "✂️  Creating 3-second bell sound for Android..."
ffmpeg -i android/app/src/main/res/raw/bell_original.mp3.bak \
    -t 3 \
    -acodec libmp3lame \
    -b:a 128k \
    android/app/src/main/res/raw/bell.mp3 \
    -y -loglevel error

# Create 3-second version for iOS
echo "✂️  Creating 3-second bell sound for iOS..."
ffmpeg -i ios/Runner/bell_original.mp3.bak \
    -t 3 \
    -acodec libmp3lame \
    -b:a 128k \
    ios/Runner/bell.mp3 \
    -y -loglevel error

# Check file sizes
echo ""
echo "✅ New file sizes:"
ls -lh android/app/src/main/res/raw/bell.mp3 | awk '{print "   Android: " $5}'
ls -lh ios/Runner/bell.mp3 | awk '{print "   iOS:     " $5}'

echo ""
echo "🎉 Done! Your notification bell sound is now fixed."
echo ""
echo "📋 Next steps:"
echo "1. Uninstall the app from your device (to clear Android notification channel cache)"
echo "2. Run: flutter clean && flutter pub get"
echo "3. Run: flutter run"
echo "4. Test notifications - you should now hear the bell sound!"
echo ""
echo "💡 Note: Original files backed up as bell_original.mp3.bak"
