#!/bin/bash

# Morefastlight - File Verification Script
# This script checks that all required source files are present

echo "🔍 Verifying Morefastlight project files..."
echo ""

MISSING=0
FOUND=0

check_file() {
    if [ -f "$1" ]; then
        echo "✅ $1"
        ((FOUND++))
    else
        echo "❌ MISSING: $1"
        ((MISSING++))
    fi
}

echo "📱 Main App:"
check_file "Morefastlight/MorefastlightApp.swift"
check_file "Morefastlight/Info.plist"
echo ""

echo "📦 Models:"
check_file "Morefastlight/Models/App.swift"
check_file "Morefastlight/Models/Config.swift"
check_file "Morefastlight/Models/QuickAction.swift"
check_file "Morefastlight/Models/CommandResult.swift"
check_file "Morefastlight/Models/PathEntry.swift"
check_file "Morefastlight/Models/SearchResult.swift"
echo ""

echo "🎨 Views:"
check_file "Morefastlight/Views/SearchWindowController.swift"
check_file "Morefastlight/Views/SearchWindow.swift"
check_file "Morefastlight/Views/SearchField.swift"
check_file "Morefastlight/Views/SearchResultRow.swift"
check_file "Morefastlight/Views/ErrorPopup.swift"
check_file "Morefastlight/Views/SettingsView.swift"
echo ""

echo "⚙️  Services:"
check_file "Morefastlight/Services/HotkeyManager.swift"
check_file "Morefastlight/Services/AppIndexer.swift"
check_file "Morefastlight/Services/AppCache.swift"
check_file "Morefastlight/Services/InputClassifier.swift"
check_file "Morefastlight/Services/CommandExecutor.swift"
check_file "Morefastlight/Services/PathAutocompleter.swift"
check_file "Morefastlight/Services/ConfigManager.swift"
echo ""

echo "🔧 Utilities:"
check_file "Morefastlight/Utilities/FuzzySearch.swift"
echo ""

echo "📚 Documentation:"
check_file "README.md"
check_file "QUICKSTART.md"
check_file "BUILD_SUMMARY.md"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Summary:"
echo "  ✅ Found: $FOUND files"
echo "  ❌ Missing: $MISSING files"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ $MISSING -eq 0 ]; then
    echo ""
    echo "🎉 All files present! Ready to build in Xcode."
    echo ""
    echo "Next steps:"
    echo "  1. Open Xcode"
    echo "  2. Create new macOS App project named 'Morefastlight'"
    echo "  3. Drag source files into project"
    echo "  4. Build and run!"
    echo ""
    echo "See QUICKSTART.md for detailed instructions."
    exit 0
else
    echo ""
    echo "⚠️  Some files are missing. Please check the project structure."
    exit 1
fi
