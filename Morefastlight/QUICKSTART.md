# Morefastlight - Quick Start Guide

## Step 1: Open Xcode

Since we can't automatically create an Xcode project file from the command line, you'll need to create it manually:

1. Open Xcode
2. Choose "Create New Project"
3. Select "macOS" → "App"
4. Fill in:
   - Product Name: `Morefastlight`
   - Team: (Your team)
   - Organization Identifier: `com.yourname` (or your preferred identifier)
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Storage: None
   - Uncheck "Create Git repository" (already in a repo)
5. Click "Next"
6. Save the project **inside** the existing `Morefastlight` directory

## Step 2: Add Source Files

1. In Xcode, delete the default files:
   - `MorefastlightApp.swift` (default one)
   - `ContentView.swift`
   - `Assets.xcassets` (we'll keep this)

2. In Finder, you'll see all the source files already organized:
   ```
   Morefastlight/
   ├── MorefastlightApp.swift
   ├── Models/
   ├── Views/
   ├── Services/
   ├── Utilities/
   └── Info.plist
   ```

3. Drag these folders into Xcode's Project Navigator:
   - Drag `Models` folder → Check "Create groups"
   - Drag `Views` folder → Check "Create groups"
   - Drag `Services` folder → Check "Create groups"
   - Drag `Utilities` folder → Check "Create groups"
   - Drag `MorefastlightApp.swift` file
   - Right-click on project → "Add Files" → Select `Info.plist`

4. Make sure all files are checked under "Target Membership" for "Morefastlight"

## Step 3: Configure Project Settings

1. Select the project in Project Navigator
2. Select the "Morefastlight" target
3. Go to "Signing & Capabilities":
   - Select your Team
   - Ensure "Automatically manage signing" is checked

4. Go to "Build Settings":
   - Search for "Deployment Target"
   - Set "macOS Deployment Target" to **13.0** or higher

5. Go to "Info" tab:
   - Verify "Custom macOS Application Target Properties" shows `LSUIElement = YES`
   - This ensures the app is menu-bar only (no dock icon)

## Step 4: Build and Run

1. Select your Mac as the build destination (next to the scheme selector)
2. Press `⌘R` or click the "Run" button
3. The app will build and launch
4. Look for the bolt icon ⚡️ in your menu bar
5. Click it to see the menu

## Step 5: Set Up Keyboard Shortcut

**Important:** Disable Spotlight first!

1. Open System Settings
2. Go to **Keyboard** → **Keyboard Shortcuts** → **Spotlight**
3. **Uncheck** "Show Spotlight search"
4. Now you can use `⌘Space` with Morefastlight!

## Step 6: Test It Out

1. Press `⌘Space` to open the search window
2. Try searching for apps:
   - Type "safari" → Press Enter
   - Type "slk" (fuzzy match for Slack) → Press Enter

3. Try running commands:
   - Type "git status" → Press Enter
   - Type "ls -la" → Press Enter

4. Try opening directories:
   - Type "~/Documents" → See quick actions
   - Press `⌘F` to open in Finder
   - Press `⌘T` to open in Terminal

5. Try tab autocomplete:
   - Type "~/Do" → Press Tab
   - Should complete to "~/Documents/"

## Common Issues

### Issue: Build fails with "Cannot find type 'X' in scope"

**Solution:** Make sure all files are added to the target
- Select each file in Project Navigator
- Check the "Target Membership" in File Inspector
- Ensure "Morefastlight" is checked

### Issue: Hotkey doesn't work

**Solution:** Grant Accessibility permissions
1. Open System Settings → Privacy & Security → Accessibility
2. Add Morefastlight to the list
3. Toggle it on
4. Restart the app

### Issue: Apps not found in search

**Solution:** Rebuild the app index
- Click menu bar icon → "Reindex Apps"
- Wait a few seconds for indexing to complete

## Next Steps

- Edit `~/.morefastlight/config.json` to customize
- Add custom quick actions in Settings
- Change the menu bar icon in `MorefastlightApp.swift` (line with "bolt.fill")

## File Organization

All source files are organized logically:

```
Models/          - Data structures (App, Config, etc.)
Views/           - SwiftUI views (SearchWindow, Settings, etc.)
Services/        - Business logic (AppCache, CommandExecutor, etc.)
Utilities/       - Helper functions (FuzzySearch, etc.)
```

This structure makes the code easy to navigate and maintain!

---

Enjoy your blazing-fast launcher! ⚡️
