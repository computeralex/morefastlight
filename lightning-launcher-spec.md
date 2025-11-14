# Morefastlight - Complete Developer Specification

**Version:** 3.0  
**Last Updated:** November 14, 2025  
**Platform:** macOS 13.0+ (Ventura and later)  
**Language:** Swift 5.9+  
**Framework:** SwiftUI + AppKit  

---

## Table of Contents

1. [Overview](#overview)
2. [Core Philosophy](#core-philosophy)
3. [Tech Stack](#tech-stack)
4. [User Interface](#user-interface)
5. [Core Features](#core-features)
6. [Input Detection & Classification](#input-detection--classification)
7. [App Launching](#app-launching)
8. [Path Detection & Directory Options](#path-detection--directory-options)
9. [Tab Autocomplete](#tab-autocomplete)
10. [Terminal Command Execution](#terminal-command-execution)
11. [Claude Code Integration](#claude-code-integration)
12. [Configuration System](#configuration-system)
13. [Caching & Performance](#caching--performance)
14. [Project Structure](#project-structure)
15. [User Flows](#user-flows)
16. [Development Phases](#development-phases)
17. [Build & Distribution](#build--distribution)

---

## Overview

Morefastlight is a minimal, blazing-fast macOS launcher that replaces Spotlight for power users who need:

1. **Instant app launching** via fuzzy search
2. **Terminal command execution** with smart output handling
3. **Smart directory opening** in Finder/Terminal/Claude Code
4. **Tab autocomplete** for paths (like shell completion)
5. **Zero lag** - every millisecond matters

**What it's NOT:**
- ❌ File search tool
- ❌ Web search engine
- ❌ Clipboard manager
- ❌ System command center

**Philosophy:** Do a few things perfectly, not many things poorly.

---

## Core Philosophy

### Design Principles

1. **Speed is Everything**
   - Hotkey response: <50ms
   - Search results: <100ms
   - No delays, no spinners, no lag

2. **Simplicity Over Features**
   - Every feature must justify its existence
   - Configuration over compilation of features
   - Extensible through config, not bloat

3. **Native & Lightweight**
   - Swift/SwiftUI for maximum performance
   - Memory footprint: <50MB idle, <100MB active
   - No Electron, no web views, no runtime overhead

4. **User-Centric Design**
   - Keyboard-first interface
   - Predictable behavior
   - Smart defaults, but configurable

---

## Tech Stack

### Core Technologies

**Language:** Swift 5.9+  
**UI Framework:** SwiftUI (search window, settings) + AppKit (menu bar)  
**IDE:** Xcode 15+  
**Target:** macOS 13.0+ (Ventura and later)  
**Architecture:** Menu bar app (LSUIElement - no dock icon)  

### Key Libraries

- **Hotkeys:** [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) or [HotKey](https://github.com/soffes/HotKey)
- **Fuzzy Search:** [Fuse-swift](https://github.com/krisk/fuse-swift) or custom implementation
- **Shell Execution:** Native `Process` API
- **File Operations:** Native `FileManager`
- **Reactive Updates:** Native `Combine` framework
- **Concurrency:** Native `async/await` and `Actor`

---

## User Interface

### Menu Bar Presence

**Icon:** 🔭 Binoculars or ⚡️ Lightning bolt (SF Symbol: `binoculars` or `bolt.fill`)  
**Location:** macOS menu bar (upper right corner)  
**Type:** LSUIElement (no dock icon, menu bar only)  

**Menu Structure:**
```
🔭 Morefastlight
├─ Search...           ⌘Space
├─ ──────────────────────────
├─ Settings...
├─ Reindex Apps
├─ ──────────────────────────
└─ Quit                ⌘Q
```

### Search Window

**Appearance:**
- Native macOS window style
- Centered on screen with keyboard focus
- 600px wide (configurable)
- Height adjusts to number of results
- Borderless, with subtle shadow
- Supports dark mode (auto-detect or manual)

**Layout:**
```
┌─────────────────────────────────────────────┐
│  [Search Input Field]                       │
│  ~/projects/myapp█                          │
└─────────────────────────────────────────────┘

  📁 Open ~/projects/myapp in Finder     ⌘F
  💻 Open ~/projects/myapp in Terminal   ⌘T
  ⚡ Open ~/projects/myapp in Claude     ⌘C
  📝 Open ~/projects/myapp in VS Code    ⌘V
```

**Keyboard Controls:**
- `↑` `↓` - Navigate results
- `Tab` - Autocomplete path
- `Enter` - Execute selected result
- `Esc` - Close window
- `⌘F` `⌘T` `⌘C` etc. - Quick action shortcuts

### Settings Panel

**Design:** Native macOS sheet/window  
**Size:** 500×600px  
**Sections:**

```
┌─────────────────────────────────────────────┐
│  ⚙️ Morefastlight Settings              │
├─────────────────────────────────────────────┤
│                                             │
│  General                                    │
│  ├─ Hotkey: [⌘Space ▼]                     │
│  ├─ Terminal App: [iTerm2 ▼]               │
│  └─ Shell: [/bin/zsh]                      │
│                                             │
│  Directory Quick Actions                    │
│  ├─ 📁 Open in Finder    ⌘F [Built-in]    │
│  ├─ 💻 Open in Terminal  ⌘T [Built-in]    │
│  ├─ ⚡ Open in Claude    ⌘C [Edit] [✓]    │
│  └─ [+ Add Custom Action]                  │
│                                             │
│  Additional App Paths                       │
│  ├─ ~/Applications/Chrome Apps              │
│  └─ [+ Add Path]                           │
│                                             │
│         [Restore Defaults]  [Save]         │
└─────────────────────────────────────────────┘
```

### Error Popup

**Shown when:** Command exits with non-zero code  
**Design:** Modal alert over search window  

```
┌─────────────────────────────────────────────┐
│  ⚠️ Command Failed                           │
├─────────────────────────────────────────────┤
│  Command: git push origin main              │
│  Exit Code: 1                               │
│                                             │
│  Error Output:                              │
│  ┌─────────────────────────────────────────┐ │
│  │ fatal: Authentication failed for        │ │
│  │ 'https://github.com/user/repo.git'      │ │
│  │                                         │ │
│  │ (selectable/copyable text)              │ │
│  └─────────────────────────────────────────┘ │
│                                             │
│          [Copy Output]  [Close]            │
└─────────────────────────────────────────────┘
```

---

## Core Features

### 1. Global Hotkey

**Default:** `⌘Space`  
**Requirements:**
- User must disable Spotlight shortcut first
- Path: System Preferences → Keyboard → Keyboard Shortcuts → Spotlight
- Alternative hotkeys: `⌥Space`, `⌘⇧Space`
- Configurable in settings

**Behavior:**
- Works system-wide (all apps, all spaces, full-screen)
- Response time: <50ms
- Opens search window centered on current screen
- Keyboard focus immediately in search field

### 2. Search Window

**Features:**
- Real-time fuzzy matching as user types
- Shows top 5-8 results
- Instant updates (<100ms)
- Arrow key navigation
- Tab autocomplete for paths
- Quick action shortcuts (⌘F, ⌘T, ⌘C, etc.)

**Visual Feedback:**
- Highlight selected result
- Show keyboard shortcuts for each action
- Dim window when losing focus
- Smooth animations (minimal, fast)

### 3. Intelligent Input Classification

The launcher automatically detects what the user wants:

| Input Type | Detection | Action |
|------------|-----------|--------|
| App name | No special chars | Fuzzy search apps |
| Command | Starts with known prefix | Execute command |
| Absolute path | Starts with `/` or `~` | Show directory options |
| Relative path | Starts with `.` or `..` | Show directory options |

**Priority Order:**
1. Known command prefix → Execute as command
2. Valid path (exists) → Show directory options
3. Everything else → Fuzzy search apps

---

## Input Detection & Classification

### Detection Algorithm

```swift
func classifyInput(_ input: String) -> InputType {
    // 1. Check for command prefix
    if commandPrefixes.contains(where: { input.hasPrefix($0) }) {
        return .command
    }
    
    // 2. Check if it's a path
    if input.hasPrefix("/") || input.hasPrefix("~") || 
       input.hasPrefix(".") || input.hasPrefix("..") {
        if FileManager.default.fileExists(atPath: expandedPath(input)) {
            return .path
        }
    }
    
    // 3. Default to app search
    return .appSearch
}
```

### Command Prefixes

Default list (user can extend in config):
```
open, cd, ls, git, npm, yarn, pnpm, brew, 
python, python3, node, curl, wget, docker, 
kubectl, ssh, scp, rsync, make, cargo, go, 
claude
```

---

## App Launching

### Indexing Strategy

**Sources:**
- `/Applications`
- `~/Applications`
- `/System/Applications` (optional)
- User-specified paths (configurable)
- Chrome/Brave PWA directories

**Index Building:**
1. Scan directories recursively (max depth: 2)
2. Find all `.app` bundles
3. Extract metadata:
   - App name (from bundle)
   - Path
   - Type (app, pwa, system)
   - Generate keywords (name variants, abbreviations)
4. Cache to binary file

**Timing:**
- First launch: Build index (~1-2 seconds)
- Subsequent launches: Load from cache (<50ms)
- Auto-refresh: Every 24 hours or on demand

### Fuzzy Search

**Algorithm:**
- Score each app based on character matches
- Prioritize:
  1. Starts with query
  2. Contains query consecutively
  3. Contains query characters in order
  4. Frequency of use (learn over time)

**Examples:**
```
Query: "slk"  → Slack (exact abbreviation)
Query: "vsc"  → Visual Studio Code
Query: "term" → Terminal, iTerm2
```

### Execution

```swift
func launchApp(_ app: App) {
    NSWorkspace.shared.launchApplication(
        at: URL(fileURLWithPath: app.path),
        options: [],
        configuration: [:]
    )
}
```

---

## Path Detection & Directory Options

### Detection

**Valid Path Types:**
- Absolute: `/Users/alex/Documents`
- Tilde: `~/Documents`
- Relative: `./src`, `../projects`

**Validation:**
```swift
func isValidPath(_ input: String) -> Bool {
    let expanded = NSString(string: input).expandingTildeInPath
    return FileManager.default.fileExists(atPath: expanded)
}
```

### Hybrid Results Display

When user types a valid directory path, show multiple action options:

```
User input: ~/projects/myapp

Results:
┌─────────────────────────────────────────────┐
│ 📁 Open ~/projects/myapp in Finder     ⌘F   │ ← Default (Enter)
│ 💻 Open ~/projects/myapp in Terminal   ⌘T   │
│ ⚡ Open ~/projects/myapp in Claude     ⌘C   │
│ 📝 Open ~/projects/myapp in VS Code    ⌘V   │
└─────────────────────────────────────────────┘
```

**Built-in Actions (Always Available):**

1. **Open in Finder**
   - Shortcut: `⌘F`
   - Command: `open {path}`
   - Default action (top result)

2. **Open in Terminal**
   - Shortcut: `⌘T`
   - Command: `osascript -e 'tell application "{terminal_app}" to do script "cd {path}"'`
   - Uses Terminal.app or iTerm2 (auto-detect)

**Configurable Actions:**

3. **Open in Claude Code** (default included)
   - Shortcut: `⌘C`
   - Command: `osascript -e 'tell application "{terminal_app}" to do script "cd {path} && claude"'`
   - Can be disabled in settings

4. **Custom Actions** (user-defined)
   - Example: VS Code, Sublime, etc.
   - User specifies name, command, shortcut
   - Unlimited custom actions

### File Paths (Not Directories)

```
User input: ~/Documents/report.pdf

Result:
┌─────────────────────────────────────────────┐
│ 📄 Open report.pdf                          │
└─────────────────────────────────────────────┘

Executes: open ~/Documents/report.pdf
```

---

## Tab Autocomplete

### Behavior

**Trigger:** Press `Tab` key in search field  
**Function:** Complete current path segment (like shell)

**Scenarios:**

1. **Single Match:**
```
Input: ~/Do[Tab]
Output: ~/Documents/
```

2. **Multiple Matches:**
```
Input: ~/Documents/p[Tab]
Matches:
  - projects/
  - presentations/
  - photos/

Behavior:
- Show list below search bar
- Tab again to cycle through
- Or ↓ arrow to select + Enter
```

3. **No Match:**
```
Input: ~/xyz[Tab]
Output: (no change, maybe subtle shake animation)
```

### Implementation

```swift
func autocomplete(_ input: String) -> [String] {
    let path = NSString(string: input).expandingTildeInPath
    let directory = (path as NSString).deletingLastPathComponent
    let prefix = (path as NSString).lastPathComponent
    
    let contents = try? FileManager.default.contentsOfDirectory(atPath: directory)
    return contents?.filter {
        $0.hasPrefix(prefix) && isDirectory("\(directory)/\($0)")
    } ?? []
}
```

### Features

- Works with absolute paths (`/Users/...`)
- Works with tilde paths (`~/...`)
- Works with relative paths (`./`, `../`)
- Only suggests directories (not files)
- Sorted alphabetically
- Case-insensitive matching

---

## Terminal Command Execution

### Command Categories

Commands are classified into two types based on intent:

### Category A: Terminal-Opening Commands

**Definition:** Commands where user wants to continue working in terminal

**List:**
- `cd <path>` - Navigate to directory

**Behavior:**
1. Detect command
2. Open Terminal.app (or iTerm2) with command
3. Close launcher immediately
4. No output popup shown

**Implementation:**

```bash
# Terminal.app
osascript -e 'tell application "Terminal" to do script "cd ~/Documents"'

# iTerm2
osascript -e 'tell application "iTerm" to create window with default profile command "cd ~/Documents"'
```

**Example:**
```
User types: cd ~/projects/myapp
Action: Terminal opens at that directory
Result: Launcher closes, user is in terminal
```

### Category B: Execute-and-Close Commands

**Definition:** Commands that run and complete (most commands)

**Examples:**
- `git status`, `git push`, `npm install`
- `ls`, `ls -la`
- `brew update`
- Any command not in Category A

**Behavior:**
1. Execute in background shell (user's default: `$SHELL` or config)
2. Capture stdout, stderr, exit code
3. **If exit code = 0:** Close launcher silently (success!)
4. **If exit code ≠ 0:** Show error popup with output

**Implementation:**

```swift
func executeCommand(_ command: String) async -> CommandResult {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/bin/zsh")
    process.arguments = ["-c", command]
    
    let outputPipe = Pipe()
    let errorPipe = Pipe()
    process.standardOutput = outputPipe
    process.standardError = errorPipe
    
    try? process.run()
    process.waitUntilExit()
    
    let output = String(data: outputPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)
    let error = String(data: errorPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)
    
    return CommandResult(
        exitCode: Int(process.terminationStatus),
        output: output ?? "",
        error: error ?? ""
    )
}
```

**Success Example:**
```
User types: git status
Action: Runs in background
Exit Code: 0
Result: Launcher closes silently
```

**Failure Example:**
```
User types: git push
Action: Runs in background
Exit Code: 1
Result: Error popup appears with output
User: Can copy error, click Close
```

### Category C: Force-Show-Output (Optional)

**Trigger:** Prefix command with `!`  
**Purpose:** Always show output, even on success

```
User types: !git status
Action: Runs command
Result: Shows output popup (even if exit code = 0)
Use case: Quick checks without opening terminal
```

### Terminal App Detection

**Auto-detect iTerm2:**
```swift
func detectTerminalApp() -> String {
    if FileManager.default.fileExists(atPath: "/Applications/iTerm.app") {
        return "iTerm2"
    }
    return "Terminal"
}
```

User can override in settings.

---

## Claude Code Integration

### Special Handling

When user types `claude <path>`:

```
User types: claude ~/projects/myapp
Action: Opens Terminal at ~/projects/myapp, runs claude
Result: Claude Code starts in that directory
```

### Directory Options Integration

When user types a valid path, include Claude Code as an option:

```
User types: ~/projects/myapp

Results:
┌─────────────────────────────────────────────┐
│ 📁 Open ~/projects/myapp in Finder     ⌘F   │
│ 💻 Open ~/projects/myapp in Terminal   ⌘T   │
│ ⚡ Open ~/projects/myapp in Claude     ⌘C   │ ← This
└─────────────────────────────────────────────┘
```

**Implementation:**
```bash
# With Terminal.app
osascript -e 'tell application "Terminal" to do script "cd ~/projects/myapp && claude"'

# With iTerm2
osascript -e 'tell application "iTerm" to create window with default profile command "cd ~/projects/myapp && claude"'
```

### Configuration

Claude Code action is:
- Pre-configured in default config
- Can be disabled by user
- Can be customized (change shortcut, command)
- Listed under "Directory Quick Actions" in settings

---

## Configuration System

### File Location

```
~/.morefastlight/
├── config.json              # User configuration
├── app_index.cache          # Cached app list
└── recent_paths.json        # Recent directory history
```

### Default config.json

```json
{
  "version": "1.0",
  "hotkey": "Cmd+Space",
  "terminal_app": "Terminal",
  "shell": "/bin/zsh",
  
  "app_search_paths": [
    "/Applications",
    "~/Applications"
  ],
  
  "command_prefixes": [
    "open", "cd", "ls", "git", "npm", "yarn", "pnpm", "brew",
    "python", "python3", "node", "curl", "wget", "docker",
    "kubectl", "ssh", "scp", "rsync", "make", "cargo", "go",
    "claude"
  ],
  
  "terminal_opening_commands": ["cd"],
  
  "force_output_prefix": "!",
  
  "directory_quick_actions": [
    {
      "id": "claude_code",
      "name": "Open in Claude Code",
      "command_template": "tell application \"{terminal_app}\" to do script \"cd {path} && claude\"",
      "shortcut": "Cmd+C",
      "icon": "terminal.fill",
      "enabled": true
    }
  ],
  
  "custom_directory_actions": [],
  
  "ui": {
    "max_results": 8,
    "result_height": 44,
    "window_width": 600,
    "dark_mode": "auto"
  },
  
  "cache": {
    "app_index_path": "~/.morefastlight/app_index.cache",
    "recent_paths_limit": 50
  }
}
```

### Configuration Schema

**Quick Action Structure:**
```json
{
  "id": "unique_identifier",
  "name": "Display Name",
  "command_template": "shell command with {path} placeholder",
  "shortcut": "Cmd+X",
  "icon": "SF Symbol name",
  "enabled": true
}
```

**Variables in command_template:**
- `{path}` - Replaced with actual path
- `{terminal_app}` - Replaced with Terminal or iTerm2
- `{shell}` - Replaced with user's shell

### Adding Custom Actions

User can add actions via Settings panel or by editing JSON:

```json
{
  "id": "vscode",
  "name": "Open in VS Code",
  "command_template": "open -a 'Visual Studio Code' {path}",
  "shortcut": "Cmd+V",
  "icon": "chevron.left.chevron.right",
  "enabled": true
}
```

### Built-in vs Configurable

**Hardcoded (cannot disable):**
- Open in Finder (⌘F)
- Open in Terminal (⌘T)

**Pre-configured (can disable/edit):**
- Open in Claude Code (⌘C)

**User-defined:**
- Unlimited custom actions
- Full control over command, shortcut, icon

---

## Caching & Performance

### Performance Targets

| Metric | Target | Critical |
|--------|--------|----------|
| Hotkey response | <50ms | ✅ YES |
| Search update | <100ms | ✅ YES |
| Cache load | <50ms | ✅ YES |
| App launch | <200ms | No |
| Index build | <2s | No |
| Memory (idle) | <50MB | No |
| Memory (active) | <100MB | No |

### App Index Cache

**Structure:**
```swift
struct AppIndexCache: Codable {
    let version: String
    let apps: [App]
    let timestamp: Date
}

struct App: Codable, Identifiable {
    let id: UUID
    let name: String
    let path: String
    let type: AppType // .app, .pwa, .system
    let keywords: [String]
    let icon: Data?
    var lastUsed: Date?
    var useCount: Int
}
```

**Strategy:**
1. Build index on first launch (~1-2s)
2. Save to binary file (faster than JSON)
3. Load from cache on subsequent launches (<50ms)
4. Rebuild when:
   - Cache is >24 hours old
   - User clicks "Reindex Apps"
   - Config paths change
   - Manual file system monitoring detects changes

**Location:** `~/.morefastlight/app_index.cache`

### Recent Paths Cache

**Purpose:** Prioritize autocomplete suggestions based on usage

**Structure:**
```json
{
  "paths": [
    {
      "path": "~/Documents",
      "frequency": 45,
      "last_accessed": "2025-11-14T10:30:00Z"
    },
    {
      "path": "~/projects/myapp",
      "frequency": 23,
      "last_accessed": "2025-11-14T09:15:00Z"
    }
  ]
}
```

**Features:**
- Track up to 50 most-used paths
- Sort by frequency × recency
- Persist to disk
- Load on startup

**Location:** `~/.morefastlight/recent_paths.json`

### In-Memory Cache

```swift
actor AppCache {
    private var apps: [App] = []
    private var config: Config?
    private var recentPaths: [PathEntry] = []
    
    func loadAppIndex() async {
        // Load from cache file or rebuild
    }
    
    func search(_ query: String) async -> [App] {
        // Fast fuzzy search
    }
    
    func recordPathAccess(_ path: String) async {
        // Update frequency/recency
    }
}
```

### Configuration Watching

Watch config file for changes and reload automatically:

```swift
class ConfigManager: ObservableObject {
    @Published var config: Config
    
    private var fileMonitor: DispatchSourceFileSystemObject?
    
    func startWatching() {
        // Monitor config.json for changes
        // Reload and update @Published property
    }
}
```

---

## Project Structure

### Xcode Project Layout

```
morefastlight/
├── morefastlightApp.swift       # App entry point (LSUIElement)
├── Models/
│   ├── App.swift                    # App data model
│   ├── Config.swift                 # Configuration model
│   ├── QuickAction.swift            # Directory action model
│   ├── CommandResult.swift          # Command execution result
│   └── PathEntry.swift              # Recent path tracking
├── Views/
│   ├── SearchWindow.swift           # Main search interface
│   ├── SearchResultRow.swift        # Individual result display
│   ├── DirectoryOptionsView.swift   # Path action options
│   ├── SettingsView.swift           # Settings panel
│   ├── QuickActionEditor.swift      # Custom action editor
│   └── ErrorPopup.swift             # Command error display
├── Services/
│   ├── AppIndexer.swift             # App discovery & indexing
│   ├── AppCache.swift               # In-memory app cache (Actor)
│   ├── CommandExecutor.swift        # Shell command execution
│   ├── PathAutocompleter.swift      # Tab completion logic
│   ├── ConfigManager.swift          # Config load/save/watch
│   ├── InputClassifier.swift        # Input type detection
│   └── RecentPathsManager.swift     # Path frequency tracking
├── Utilities/
│   ├── FuzzySearch.swift            # Fuzzy matching algorithm
│   ├── HotkeyManager.swift          # Global hotkey handling
│   ├── TerminalDetector.swift       # Detect Terminal vs iTerm2
│   └── PathExpander.swift           # Tilde & relative path expansion
├── Resources/
│   ├── Assets.xcassets              # Icons, colors
│   └── Info.plist                   # LSUIElement = YES
└── Tests/
    ├── FuzzySearchTests.swift
    ├── InputClassifierTests.swift
    └── PathAutocompletionTests.swift
```

### Key Swift Files

#### morefastlightApp.swift
```swift
import SwiftUI

@main
struct morefastlightApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        Settings {
            SettingsView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var searchWindow: SearchWindowController?
    let hotkeyManager = HotkeyManager()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Setup menu bar icon
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem?.button?.image = NSImage(systemSymbolName: "binoculars", accessibilityDescription: "morefastlight")
        
        // Setup menu
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Search...", action: #selector(showSearch), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(showSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: "Reindex Apps", action: #selector(reindexApps), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem?.menu = menu
        
        // Register global hotkey
        hotkeyManager.register { [weak self] in
            self?.showSearch()
        }
        
        // Load app index
        Task {
            await AppCache.shared.loadAppIndex()
        }
    }
    
    @objc func showSearch() {
        searchWindow?.showWindow(self)
    }
    
    @objc func showSettings() {
        // Open settings
    }
    
    @objc func reindexApps() {
        Task {
            await AppCache.shared.rebuildIndex()
        }
    }
}
```

#### SearchWindow.swift
```swift
import SwiftUI

struct SearchWindow: View {
    @State private var query = ""
    @State private var results: [SearchResult] = []
    @State private var selectedIndex = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Search field
            TextField("Search apps, run commands, or navigate paths...", text: $query)
                .textFieldStyle(.plain)
                .font(.system(size: 18))
                .padding()
                .onChange(of: query) { _ in
                    Task {
                        await updateResults()
                    }
                }
            
            // Results
            if !results.isEmpty {
                Divider()
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(results.enumerated()), id: \.element.id) { index, result in
                            SearchResultRow(
                                result: result,
                                isSelected: index == selectedIndex
                            )
                            .onTapGesture {
                                executeResult(result)
                            }
                        }
                    }
                }
                .frame(maxHeight: 400)
            }
        }
        .frame(width: 600)
        .background(.ultraThinMaterial)
    }
    
    func updateResults() async {
        let classifier = InputClassifier()
        let type = classifier.classify(query)
        
        switch type {
        case .appSearch:
            results = await AppCache.shared.search(query)
        case .path:
            results = PathHandler.generateOptions(for: query)
        case .command:
            results = [CommandResult(command: query)]
        }
    }
    
    func executeResult(_ result: SearchResult) {
        // Execute the selected action
    }
}
```

---

## User Flows

### Flow 1: Launch an App

```
1. User presses: ⌘Space
2. Window appears (centered, focused)
3. User types: "slk"
4. Results appear instantly:
   → Slack
   → Silkypix Pro
5. User presses: Enter
6. Slack launches
7. Window closes
```

### Flow 2: Open Directory in Claude Code

```
1. User presses: ⌘Space
2. User types: "~/proj[Tab]"
3. Autocompletes to: "~/projects/"
4. User continues: "~/projects/myapp"
5. Results appear:
   📁 Open ~/projects/myapp in Finder     ⌘F
   💻 Open ~/projects/myapp in Terminal   ⌘T
   ⚡ Open ~/projects/myapp in Claude     ⌘C
6. User presses: ⌘C
7. Terminal opens, runs: cd ~/projects/myapp && claude
8. Claude Code starts
9. Window closes
```

### Flow 3: Navigate to Directory

```
1. User presses: ⌘Space
2. User types: "cd ~/Documents"
3. User presses: Enter
4. Terminal opens at ~/Documents
5. Window closes
```

### Flow 4: Run Command (Success)

```
1. User presses: ⌘Space
2. User types: "git status"
3. User presses: Enter
4. Command runs in background
5. Exit code: 0 (success)
6. Window closes silently
```

### Flow 5: Run Command (Failure)

```
1. User presses: ⌘Space
2. User types: "git push"
3. User presses: Enter
4. Command runs in background
5. Exit code: 1 (failure)
6. Error popup appears:
   ┌────────────────────────────────┐
   │ Command: git push              │
   │ Exit Code: 1                   │
   │                                │
   │ Error: fatal: Authentication   │
   │ failed...                      │
   │                                │
   │ [Copy Output] [Close]          │
   └────────────────────────────────┘
7. User copies error message
8. User clicks Close
```

### Flow 6: Force Show Output

```
1. User presses: ⌘Space
2. User types: "!ls -la"
3. User presses: Enter
4. Command runs
5. Exit code: 0 (success)
6. Output popup appears (showing directory listing)
7. User reviews output
8. User clicks Close
```

### Flow 7: Path Autocomplete

```
1. User presses: ⌘Space
2. User types: "~/Do[Tab]"
3. Autocompletes to: "~/Documents/"
4. User types: "pr[Tab]"
5. Multiple matches:
   → projects/
   → presentations/
   → photos/
6. User presses Tab to cycle (or ↓ to select)
7. Selects: "projects/"
8. Path now: "~/Documents/projects/"
9. User presses: ⌘T
10. Terminal opens at that location
```

### Flow 8: Add Custom Quick Action

```
1. User clicks menu bar icon
2. Selects: Settings...
3. In "Directory Quick Actions" section
4. Clicks: [+ Add Custom Action]
5. Dialog appears:
   Name: Open in VS Code
   Command: open -a 'Visual Studio Code' {path}
   Shortcut: Cmd+V
   Icon: chevron.left.chevron.right
6. Clicks: Save
7. New action appears in list
8. Now available in directory results
```

---

## Development Phases

### Phase 1: Core Foundation (Week 1)

**Goal:** Basic working launcher

- [ ] Create Xcode project
- [ ] Setup menu bar app (LSUIElement)
- [ ] Implement global hotkey listener
- [ ] Create basic search window (SwiftUI)
- [ ] Build app indexer (scan /Applications)
- [ ] Implement fuzzy search algorithm
- [ ] Launch apps on Enter
- [ ] Close window on Esc

**Deliverable:** Can search and launch apps

### Phase 2: Commands & Paths (Week 2)

**Goal:** Add command execution and path handling

- [ ] Input classifier (app vs command vs path)
- [ ] Command executor service
- [ ] Path detection and validation
- [ ] Hardcoded Finder action
- [ ] Hardcoded Terminal action
- [ ] Error popup for failed commands
- [ ] Basic config.json support

**Deliverable:** Can run commands and open directories

### Phase 3: Autocomplete & Polish (Week 3)

**Goal:** Tab completion and configuration

- [ ] Tab autocomplete for paths
- [ ] Settings panel (SwiftUI)
- [ ] Claude Code action (pre-configured)
- [ ] Custom action editor
- [ ] App index caching (binary format)
- [ ] Recent paths tracking
- [ ] iTerm2 detection

**Deliverable:** Full feature set complete

### Phase 4: Refinement (Week 4)

**Goal:** Polish, performance, testing

- [ ] Icon design (menu bar + app)
- [ ] Dark mode support
- [ ] Performance optimization
- [ ] Memory profiling
- [ ] Edge case handling
- [ ] User testing
- [ ] Bug fixes
- [ ] Documentation

**Deliverable:** Production-ready app

---

## Build & Distribution

### Development

**Requirements:**
- macOS 13.0+ (Ventura)
- Xcode 15+
- Apple Developer account (for code signing)

**Build Commands:**
```bash
# Open project
open morefastlight.xcodeproj

# Command-line build
xcodebuild -scheme morefastlight -configuration Release build

# Run
xcodebuild -scheme morefastlight -configuration Debug run
```

### Code Signing

**For Development:**
```bash
# Use "Sign to Run Locally" in Xcode
# No developer account needed for personal use
```

**For Distribution:**
```bash
# Sign with Developer ID
codesign --deep --force --verify --verbose \
  --sign "Developer ID Application: Your Name" \
  --options runtime \
  morefastlight.app
```

### Notarization

**Required for:** Distribution outside App Store

**Process:**
```bash
# 1. Create archive
xcodebuild -scheme morefastlight archive \
  -archivePath morefastlight.xcarchive

# 2. Export for notarization
xcodebuild -exportArchive \
  -archivePath morefastlight.xcarchive \
  -exportPath . \
  -exportOptionsPlist exportOptions.plist

# 3. Create ZIP
ditto -c -k --keepParent morefastlight.app morefastlight.zip

# 4. Submit for notarization
xcrun notarytool submit morefastlight.zip \
  --apple-id your@email.com \
  --password app-specific-password \
  --team-id TEAM_ID \
  --wait

# 5. Staple ticket
xcrun stapler staple morefastlight.app
```

### Distribution Options

**1. Direct Download**
- Zip the signed .app bundle
- Host on GitHub Releases or website
- Users drag to Applications folder

**2. Homebrew Cask**
```ruby
cask "morefastlight" do
  version "1.0.0"
  sha256 "..."
  
  url "https://github.com/username/morefastlight/releases/download/v#{version}/morefastlight.zip"
  name "morefastlight"
  desc "Fast macOS app launcher"
  homepage "https://github.com/username/morefastlight"
  
  app "morefastlight.app"
end
```

Installation:
```bash
brew install --cask morefastlight
```

**3. Mac App Store** (Optional)
- Requires $99/year Apple Developer Program
- Longer review process
- Sandboxing restrictions may complicate features
- Built-in auto-updates

**4. GitHub Releases**
- Free hosting
- Version tracking
- Download analytics
- Update notifications (via Sparkle framework)

### Auto-Updates (Optional)

Use [Sparkle](https://sparkle-project.org/):

```swift
import Sparkle

@main
struct morefastlightApp: App {
    let updaterController = SPUStandardUpdaterController(
        startingUpdater: true,
        updaterDelegate: nil,
        userDriverDelegate: nil
    )
    
    var body: some Scene {
        Settings {
            SettingsView()
        }
        .commands {
            CommandGroup(after: .appInfo) {
                CheckForUpdatesView(updater: updaterController.updater)
            }
        }
    }
}
```

### Uninstallation

**User Instructions:**
```
1. Quit app (via menu bar icon)
2. Delete: /Applications/morefastlight.app
3. Delete: ~/.morefastlight/ (optional, removes settings)
```

**Optional Uninstaller Script:**
```bash
#!/bin/bash
# uninstall.sh

rm -rf /Applications/morefastlight.app
rm -rf ~/.morefastlight/

echo "Morefastlight uninstalled successfully"
```

---

## Testing Strategy

### Unit Tests

**Test Coverage:**
- [ ] Fuzzy search algorithm
- [ ] Input classification
- [ ] Path expansion (tilde, relative)
- [ ] Path autocomplete logic
- [ ] Config parsing/validation
- [ ] Command template interpolation

**Example Test:**
```swift
class FuzzySearchTests: XCTestCase {
    func testExactMatch() {
        let apps = [App(name: "Slack"), App(name: "Safari")]
        let results = FuzzySearch.search("slack", in: apps)
        XCTAssertEqual(results.first?.name, "Slack")
    }
    
    func testAbbreviation() {
        let apps = [App(name: "Visual Studio Code")]
        let results = FuzzySearch.search("vsc", in: apps)
        XCTAssertEqual(results.first?.name, "Visual Studio Code")
    }
}
```

### Integration Tests

- [ ] App indexing from file system
- [ ] Cache save/load cycle
- [ ] Config file watching
- [ ] Command execution (mocked shell)
- [ ] Hotkey registration

### Manual Testing Checklist

**Core Features:**
- [ ] Hotkey works in all apps
- [ ] Search updates instantly (<100ms)
- [ ] Apps launch correctly
- [ ] Commands execute properly
- [ ] Paths open in correct app
- [ ] Tab autocomplete works
- [ ] Error popup appears on command failure

**Edge Cases:**
- [ ] Non-existent path handling
- [ ] Invalid command handling
- [ ] Empty search results
- [ ] Very long paths
- [ ] Special characters in paths
- [ ] Permissions errors
- [ ] Terminal/iTerm2 not installed
- [ ] Claude not installed

**UI/UX:**
- [ ] Window appears on correct screen
- [ ] Dark mode works
- [ ] Keyboard navigation smooth
- [ ] Animations not janky
- [ ] Settings save/load properly
- [ ] Menu bar icon visible

**Performance:**
- [ ] Hotkey response <50ms
- [ ] Search update <100ms
- [ ] Memory usage <100MB
- [ ] No leaks after extended use

---

## Success Criteria

**Must Have:**
1. ✅ Hotkey response <50ms
2. ✅ Search results <100ms
3. ✅ App launching works 100%
4. ✅ Command execution reliable
5. ✅ Path autocomplete functional
6. ✅ Settings persist correctly

**Should Have:**
1. Memory usage <100MB
2. Dark mode support
3. iTerm2 auto-detection
4. Custom actions working
5. Cache performance optimized

**Nice to Have:**
1. Menu bar icon animated
2. Result usage tracking
3. Command history
4. Workflow automation hooks

---

## Known Limitations

1. **No Spotlight Integration:** Cannot disable Spotlight programmatically - user must do it manually
2. **Sandboxing:** If published to Mac App Store, some features may be restricted
3. **Terminal Detection:** Relies on checking file system for iTerm2, not perfect
4. **Command Execution:** Runs in shell, may have different environment than user's terminal
5. **Path Autocomplete:** Only suggests directories, not files

---

## Future Enhancements (Post-V1)

**Phase 2 Features:**
- [ ] Plugin system for extensibility
- [ ] Workflow automation (à la Alfred)
- [ ] Snippet expansion
- [ ] Calculator mode
- [ ] Unit conversion
- [ ] Command aliases
- [ ] Sync settings via iCloud

**Phase 3 Features:**
- [ ] AI-powered suggestions
- [ ] Natural language commands
- [ ] Smart learning from usage patterns
- [ ] Team sharing of configs
- [ ] Remote machine integration

---

## FAQ for Developers

### Q: Why Swift instead of Electron?

**A:** Performance. Swift apps are native, use less memory, start faster, and feel more responsive. Electron adds 100-200MB overhead and slower startup.

### Q: Why not use Spotlight's index?

**A:** Spotlight indexing can be slow/broken (as you experienced). We only need apps, not files, so building our own index is faster and more reliable.

### Q: How do we handle app updates?

**A:** Apps rarely change names/locations. We rebuild index every 24 hours or on manual trigger. Could add file system monitoring for real-time updates if needed.

### Q: What about security/privacy?

**A:** App runs locally, no network calls, no telemetry. Commands execute with user's permissions. Config stored locally. Open source = auditable.

### Q: How to test global hotkey?

**A:** Use `KeyboardShortcuts` library which handles all the complexity. Test by registering in `applicationDidFinishLaunching`.

### Q: Memory management strategy?

**A:** Use Swift's ARC. Minimize retained data. Cache apps but not search results. Use `weak` references for delegates.

---

## Resources

**Documentation:**
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui/)
- [AppKit Documentation](https://developer.apple.com/documentation/appkit/)
- [Process API](https://developer.apple.com/documentation/foundation/process)
- [FileManager](https://developer.apple.com/documentation/foundation/filemanager)

**Libraries:**
- [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts)
- [Fuse-swift](https://github.com/krisk/fuse-swift)
- [Sparkle](https://sparkle-project.org/) (for updates)

**Similar Projects (for reference):**
- [Raycast](https://www.raycast.com/) - Closed source, but similar concept
- [Alfred](https://www.alfredapp.com/) - The original
- [Quicksilver](https://qsapp.com/) - Open source predecessor

---

## Contact & Support

**Developer:** [Your Name]  
**GitHub:** https://github.com/username/morefastlight  
**Issues:** https://github.com/username/morefastlight/issues  
**Discussions:** https://github.com/username/morefastlight/discussions  

---

## License

MIT License - Free to use, modify, and distribute.

---

## Appendix: Example Configs

### Minimal Config
```json
{
  "version": "1.0",
  "hotkey": "Cmd+Space",
  "terminal_app": "Terminal",
  "directory_quick_actions": []
}
```

### Power User Config
```json
{
  "version": "1.0",
  "hotkey": "Option+Space",
  "terminal_app": "iTerm2",
  "shell": "/bin/zsh",
  
  "app_search_paths": [
    "/Applications",
    "~/Applications",
    "/Applications/Utilities",
    "~/Applications/Chrome Apps",
    "~/Applications/Setapp"
  ],
  
  "command_prefixes": [
    "open", "cd", "ls", "git", "npm", "yarn", "pnpm", "brew",
    "python", "python3", "node", "curl", "wget", "docker",
    "kubectl", "ssh", "scp", "rsync", "make", "cargo", "go",
    "claude", "vim", "nvim", "code"
  ],
  
  "directory_quick_actions": [
    {
      "id": "claude_code",
      "name": "Claude Code",
      "command_template": "tell application \"{terminal_app}\" to do script \"cd {path} && claude\"",
      "shortcut": "Cmd+C",
      "icon": "terminal.fill",
      "enabled": true
    },
    {
      "id": "vscode",
      "name": "VS Code",
      "command_template": "open -a 'Visual Studio Code' {path}",
      "shortcut": "Cmd+V",
      "icon": "chevron.left.chevron.right",
      "enabled": true
    },
    {
      "id": "fork",
      "name": "Fork (Git Client)",
      "command_template": "open -a 'Fork' {path}",
      "shortcut": "Cmd+G",
      "icon": "arrow.triangle.branch",
      "enabled": true
    }
  ],
  
  "ui": {
    "max_results": 10,
    "window_width": 700,
    "dark_mode": "dark"
  }
}
```

---

**END OF SPECIFICATION**

---

This spec is a living document. Update as you build and discover what works best!

Good luck building Morefastlight! ⚡️
