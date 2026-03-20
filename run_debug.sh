#!/bin/bash

# Debug script for Bible app database migration issues
# This script helps diagnose and fix data loss after app update

echo "🔍 Bible App Database Migration Debug Script"
echo "============================================="

# Check if flutter is available
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter not found. Please install Flutter first."
    exit 1
fi

echo "📱 Running debug diagnostics..."

# Run the app with debug logging enabled
echo "🚀 Starting app with enhanced debug logging..."
echo "   Look for these log patterns:"
echo "   - 'DB_FILES_CHECK:' - Database file status"
echo "   - 'LIBRARY_COUNTS:' - User data counts"
echo "   - 'copyUserDataFromLegacyIfNeeded:' - Migration attempts"
echo "   - 'testapp Migration:' - Migration progress"
echo ""
echo "📋 Common issues and solutions:"
echo "   1. If 'LIBRARY_COUNTS' shows 0 for all tables:"
echo "      - Migration failed or legacy DB not found"
echo "      - Check 'DB_FILES_CHECK' for available DB files"
echo ""
echo "   2. If legacy DB files exist but migration didn't work:"
echo "      - Race condition in splash screen"
echo "      - Migration logic skipped incorrectly"
echo ""
echo "   3. If you see 'copyUserDataFromLegacyIfNeeded: no legacy source DB':"
echo "      - Legacy DB was deleted too early"
echo "      - Check for .bak files that might contain data"
echo ""

# Run flutter with debug output
flutter run --debug --verbose

echo ""
echo "🔧 If issues persist, try these manual recovery steps:"
echo "   1. Force stop the app"
echo "   2. Clear app cache (not data)"
echo "   3. Restart the app"
echo "   4. Check My Library sections"
echo ""
echo "📞 If data is still missing, the emergency recovery method"
echo "   will be triggered automatically when you open Library screens."