# Morefastlight - Security, Best Practices & Distribution Guide

## 🚨 CRITICAL SECURITY VULNERABILITIES

### 1. **AppleScript Injection** (HIGH SEVERITY)
**Location:** `CommandExecutor.swift:30-50, 95-121`

**Problem:**
```swift
script = """
tell application "Terminal"
    do script "\(command)"  // ⚠️ INJECTION POINT!
end tell
"""
```

If user types: `~/test" & do shell script "rm -rf ~" & "`
This executes arbitrary code!

**Fix:**
```swift
private func escapeAppleScriptString(_ str: String) -> String {
    return str
        .replacingOccurrences(of: "\\", with: "\\\\")
        .replacingOccurrences(of: "\"", with: "\\\"")
}

// Then use:
do script "\(escapeAppleScriptString(command))"
```

### 2. **Shell Command Injection** (HIGH SEVERITY)
**Location:** `CommandExecutor.swift:52-88, 92, 154-164`

**Problem:**
```swift
executeShellCommand("open \"\(expandedPath)\"")
```

Path like: `/tmp/test"; rm -rf ~ #` would execute deletion!

**Fix:** Use `Process` with separate arguments instead of shell:
```swift
func openDirectoryInFinder(_ path: String) {
    let expandedPath = NSString(string: path).expandingTildeInPath
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
    process.arguments = [expandedPath]  // Safe - no shell interpretation
    try? process.run()
}
```

### 3. **Path Traversal** (MEDIUM SEVERITY)
**Location:** `PathAutocompleter.swift`, `CommandExecutor.swift`

**Problem:** No validation that paths are safe. User could access:
- `/etc/passwd`
- `~/.ssh/`
- System directories

**Fix:** Add path validation:
```swift
private func isSafePath(_ path: String) -> Bool {
    let expandedPath = NSString(string: path).expandingTildeInPath

    // Disallow sensitive directories
    let forbidden = ["/etc/", "/var/", "/private/", "/.ssh/", "/System/Library/"]
    for prefix in forbidden {
        if expandedPath.hasPrefix(prefix) {
            return false
        }
    }

    // Only allow user home and common directories
    let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
    let allowed = [homeDir, "/Applications", "/Users"]

    return allowed.contains { expandedPath.hasPrefix($0) }
}
```

---

## 💻 CODING BEST PRACTICES IMPROVEMENTS

### 1. **Memory Leaks**
**Issue:** Global event monitor may leak if app crashes
**Fix:**
```swift
// In SearchWindowController
class SearchWindowController: NSWindowController {
    deinit {
        cleanup()
    }

    private func cleanup() {
        if let monitor = clickMonitor {
            NSEvent.removeMonitor(monitor)
            clickMonitor = nil
        }
    }
}
```
✅ Already implemented!

### 2. **Error Handling**
**Issue:** Silent failures in many places
**Improvements needed:**
- Log errors to user-visible location
- Add crash reporting (optional)
- Graceful degradation

```swift
// Add logging system
enum AppLogger {
    static func error(_ message: String, error: Error? = nil) {
        NSLog("❌ ERROR: \(message) - \(error?.localizedDescription ?? "")")
        // Could add to ~/Library/Logs/Morefastlight/
    }
}
```

### 3. **Configuration Validation**
**Issue:** No validation of config values
**Fix:**
```swift
struct Config: Codable {
    var hotkey: String {
        didSet {
            // Validate hotkey format
            assert(isValidHotkey(hotkey), "Invalid hotkey format")
        }
    }

    private func isValidHotkey(_ key: String) -> Bool {
        // Validate format like "Cmd+Space"
        return true  // Implement validation
    }
}
```

### 4. **Actor Isolation**
**Issue:** AppCache actor but not consistently used
**Improvement:** Ensure all app cache access is through actor:
```swift
actor AppCache {
    // All methods already properly isolated ✅
}

// Usage
await appCache.search(query)  // ✅ Correct
```

---

## ⚡ SYSTEM RESOURCE CONCERNS

### Current Resource Usage:

1. **Global Event Monitor**
   - ✅ Only active when window is open
   - ✅ Properly cleaned up
   - Impact: Minimal (only mouse events)

2. **Reindex Timer**
   - ⚠️ Runs every 24 hours by default
   - ⚠️ No way to pause/disable
   - Impact: Moderate (scans /Applications recursively)

**Improvement:**
```swift
// Only reindex when app is active, not in background
func scheduleReindexing() {
    timer = Timer.scheduledTimer(withTimeInterval: hours * 3600, repeats: true) { [weak self] _ in
        guard NSApp.isActive else { return }  // Skip if inactive
        Task {
            await self?.appCache.rebuildIndex()
        }
    }
}
```

3. **App Index Cache**
   - ✅ Stored in memory (actor)
   - Size: ~1-5KB for 100-200 apps
   - Impact: Negligible

4. **SwiftUI View Recreation**
   - ⚠️ Creates new view hierarchy on each open
   - Could accumulate memory if opened rapidly
   - Impact: Low-Medium

**Improvement:**
```swift
// Add debouncing
private var lastOpenTime: Date?

override func showWindow(_ sender: Any?) {
    // Prevent rapid reopening
    if let last = lastOpenTime, Date().timeIntervalSince(last) < 0.5 {
        return
    }
    lastOpenTime = Date()
    // ... rest of code
}
```

---

## ⚙️ HOTKEY CONFIGURATION IN SETTINGS

**Current:** Hardcoded in Info.plist and app
**Should be:** User-configurable in Settings

**Implementation:**
1. Use `KeyboardShortcuts` package or native hotkey capture
2. Store in UserDefaults/Config
3. Re-register hotkey when changed

```swift
// Add to SettingsView
HotkeyRecorder(hotkey: $config.hotkey) {
    // Re-register global hotkey
    HotkeyManager.shared.unregister()
    HotkeyManager.shared.register(config.hotkey)
}
```

**Note:** This requires Carbon framework usage - complex to implement correctly!

---

## 📦 PACKAGING FOR DISTRIBUTION

### Option 1: Direct DMG Distribution

**Steps:**
1. **Archive build:**
   ```bash
   xcodebuild archive \
     -scheme Morefastlight \
     -archivePath ./build/Morefastlight.xcarchive
   ```

2. **Export app:**
   ```bash
   xcodebuild -exportArchive \
     -archivePath ./build/Morefastlight.xcarchive \
     -exportPath ./build \
     -exportOptionsPlist ExportOptions.plist
   ```

3. **Create DMG:**
   ```bash
   # Install create-dmg
   brew install create-dmg

   # Create DMG
   create-dmg \
     --volname "Morefastlight" \
     --volicon "icon.icns" \
     --window-pos 200 120 \
     --window-size 600 400 \
     --icon-size 100 \
     --icon "Morefastlight.app" 175 120 \
     --hide-extension "Morefastlight.app" \
     --app-drop-link 425 120 \
     "Morefastlight-1.0.dmg" \
     "build/Morefastlight.app"
   ```

4. **Code Sign:**
   ```bash
   # Get your Developer ID
   security find-identity -v -p codesigning

   # Sign the app
   codesign --deep --force --verify --verbose \
     --sign "Developer ID Application: YOUR NAME" \
     Morefastlight.app
   ```

5. **Notarize** (required for Gatekeeper):
   ```bash
   # Create app-specific password in Apple ID
   # Then notarize
   xcrun notarytool submit Morefastlight-1.0.dmg \
     --apple-id your@email.com \
     --team-id TEAMID \
     --password "app-specific-password" \
     --wait

   # Staple the notarization
   xcrun stapler staple Morefastlight-1.0.dmg
   ```

**Requirements:**
- Apple Developer Account ($99/year)
- Developer ID certificate
- Notarization

### Option 2: GitHub Releases

**Advantages:**
- Free
- Automatic updates possible
- Version history

**Setup:**
1. Create release on GitHub
2. Upload DMG as asset
3. Users download and drag to Applications

---

## 🍺 HOMEBREW DISTRIBUTION

### Create a Homebrew Cask

**File:** `morefastlight.rb`
```ruby
cask "morefastlight" do
  version "1.0.0"
  sha256 "SHA256_OF_DMG_FILE"

  url "https://github.com/computeralex/morefastlight/releases/download/v#{version}/Morefastlight-#{version}.dmg"
  name "Morefastlight"
  desc "Blazing-fast macOS launcher with Terminal integration"
  homepage "https://github.com/computeralex/morefastlight"

  livecheck do
    url :url
    strategy :github_latest
  end

  app "Morefastlight.app"

  zap trash: [
    "~/Library/Application Support/Morefastlight",
    "~/Library/Caches/com.mohrcomputer.Morefastlight",
    "~/Library/Preferences/com.mohrcomputer.Morefastlight.plist",
    "~/.morefastlight",
  ]
end
```

**Distribution Options:**

1. **homebrew-cask (official):**
   - PR to https://github.com/Homebrew/homebrew-cask
   - Strict requirements
   - High visibility
   - Automatic updates

2. **Personal tap (easier):**
   ```bash
   # Create tap repo
   gh repo create homebrew-morefastlight --public

   # Add cask
   mkdir -p Casks
   cp morefastlight.rb Casks/
   git add . && git commit -m "Add Morefastlight cask"
   git push

   # Users install with:
   brew tap computeralex/morefastlight
   brew install --cask morefastlight
   ```

---

## 👤 AUTHOR NAME & GITHUB STRATEGY

### Changing Author Attribution

**Option 1: Keep in same repo with new commits**
```bash
# Future commits will have new author
git config user.name "Your New Name"
git config user.email "your@email.com"

# Old commits stay with "Claude"
```

**Option 2: Rewrite history (NOT RECOMMENDED if already pushed)**
```bash
# Rewrites all commits - breaks for anyone who cloned
git filter-branch --env-filter '
  if [ "$GIT_AUTHOR_EMAIL" = "noreply@anthropic.com" ]
  then
    export GIT_AUTHOR_NAME="Your Name"
    export GIT_AUTHOR_EMAIL="your@email.com"
  fi
' --tag-name-filter cat -- --branches --tags
```

**Option 3: Fork to new repo**
```bash
# Create new repo
gh repo create your-new-morefastlight --public

# Add new remote
git remote add new-repo https://github.com/YOU/your-new-morefastlight.git

# Push to new repo
git push new-repo main

# Add attribution in README
echo "Originally created with Claude Code assistance" >> README.md
```

### Recommended Approach:
- **Keep original repo:** `computeralex/morefastlight` with Claude commits
- **Future commits:** Use your name
- **README:** Add "Built with Claude Code assistance"
- **Fork if needed:** For variant/different project

---

## 🏪 APP STORE DISTRIBUTION

### Can Morefastlight go to Mac App Store?

**Issues:**

1. **❌ Sandboxing Required**
   - App Store requires full sandboxing
   - This breaks:
     - ✗ Running shell commands (`Process` with `/bin/zsh`)
     - ✗ AppleScript to control Terminal
     - ✗ Global hotkeys (Carbon framework)
     - ✗ Accessing `/Applications` directory

2. **❌ Entitlements Conflicts**
   ```xml
   <!-- App Store requires -->
   <key>com.apple.security.app-sandbox</key>
   <true/>

   <!-- But we need (incompatible with sandbox): -->
   <key>com.apple.security.automation.apple-events</key>  <!-- AppleScript -->
   <key>com.apple.security.files.user-selected.read-only</key>
   ```

3. **❌ Review Guidelines**
   - Duplicates macOS Spotlight functionality
   - Apple may reject

### App Store Verdict: **NOT FEASIBLE** without major rewrites

**Alternatives:**
1. ✅ **Direct distribution** (DMG + notarization)
2. ✅ **Homebrew** (easiest for developers)
3. ✅ **Setapp** (paid app marketplace, less restrictive)
4. ❌ App Store (not compatible)

---

## 🎯 RECOMMENDED ACTION PLAN

### Immediate (Security Critical):
1. ✅ **Fix AppleScript injection** in CommandExecutor
2. ✅ **Fix shell command injection** in CommandExecutor
3. ✅ **Add path validation** in PathAutocompleter

### Short Term (Quality):
4. ⚠️ Add error logging system
5. ⚠️ Add config validation
6. ⚠️ Make hotkey configurable in Settings
7. ⚠️ Remove all debug print statements

### Medium Term (Distribution):
8. 📦 Code signing setup
9. 📦 Notarization setup
10. 📦 Create DMG build script
11. 📦 GitHub Releases automation
12. 🍺 Homebrew tap creation

### Long Term (Polish):
13. 💎 Add update checker
14. 💎 Add analytics (optional, privacy-respecting)
15. 💎 Add crash reporting
16. 💎 Performance optimizations

---

## 📊 DISTRIBUTION COMPARISON

| Method | Setup Difficulty | Reach | Auto Updates | Cost |
|--------|-----------------|-------|--------------|------|
| GitHub Releases | Easy | Medium | Via Sparkle | Free |
| Homebrew Cask | Medium | High (devs) | Yes | Free |
| Direct Download | Easy | Low | No | Free |
| Setapp | Hard | Medium | Yes | 30% revenue |
| Mac App Store | **Impossible** | High | Yes | $99/yr + 30% |

**Recommended:** GitHub Releases + Homebrew Cask

---

## 🔐 PRIVACY CONSIDERATIONS

Current data collection: **NONE** ✅

Future considerations:
- ❌ Don't collect search queries
- ❌ Don't send usage data without explicit opt-in
- ✅ All processing happens locally
- ✅ No network requests

---

## 📝 LICENSE CONSIDERATIONS

Current: No LICENSE file

**Recommendations:**
- MIT License (permissive, good for tools)
- Apache 2.0 (patent protection)
- GPL 3.0 (copyleft, requires derivatives to be open)

**For this project:** MIT is recommended

```markdown
# MIT License

Copyright (c) 2024 [Your Name]

Created with Claude Code assistance.
```

---

## 🚀 SUMMARY

**Critical Actions:**
1. Fix security vulnerabilities (AppleScript/shell injection)
2. Choose distribution method (recommend: GitHub + Homebrew)
3. Get Apple Developer ID if distributing signed DMG
4. Add LICENSE file

**Not Feasible:**
- ❌ Mac App Store (sandboxing conflicts)

**Best Distribution Path:**
1. Fix security issues
2. Create signed + notarized DMG
3. Post on GitHub Releases
4. Submit to Homebrew Cask
5. Promote on Reddit, Hacker News

Would you like me to implement the security fixes first?
