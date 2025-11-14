# Morefastlight

A minimal, blazing-fast macOS launcher that replaces Spotlight for power users.

## Features

- **Instant app launching** via fuzzy search
- **Terminal command execution** with smart output handling
- **Smart directory opening** in Finder/Terminal/Claude Code
- **Tab autocomplete** for paths (like shell completion)
- **Zero lag** - every millisecond matters

## Building from Source

### Prerequisites

- macOS 13.0+ (Ventura or later)
- Xcode 15+
- Swift 5.9+

### Setup Instructions

1. **Create Xcode Project**

   Open Xcode and create a new project:
   - Choose "macOS" → "App"
   - Product Name: `Morefastlight`
   - Interface: SwiftUI
   - Language: Swift
   - Bundle Identifier: `com.yourname.Morefastlight`

2. **Add Source Files**

   The source files are already created in the `Morefastlight` directory. In Xcode:
   - Delete the default `MorefastlightApp.swift` and `ContentView.swift` files
   - Drag all the source files from the `Morefastlight/` directory into your Xcode project
   - Make sure to check "Copy items if needed"
   - Ensure all files are added to the Morefastlight target

3. **Configure Info.plist**

   The `Info.plist` file is already configured with:
   - `LSUIElement` = `true` (this makes the app menu-bar only, no dock icon)
   - Minimum system version: macOS 13.0

4. **Build Settings**

   In Xcode, configure the following:
   - Go to Project Settings → Signing & Capabilities
   - Set your Team (for code signing)
   - Deployment Target: macOS 13.0 or later

5. **Build and Run**

   - Press `⌘R` to build and run
   - The app will appear in the menu bar with a bolt icon ⚡️
   - Press `⌘Space` to open the search window (you may need to disable Spotlight first)

### Disabling Spotlight

Before using Morefastlight with `⌘Space`, you need to disable Spotlight's keyboard shortcut:

1. Open System Settings
2. Go to Keyboard → Keyboard Shortcuts → Spotlight
3. Uncheck "Show Spotlight search"

## Usage

### Launching Apps

Type the name of any application and press Enter:
```
slack      → Launches Slack
vsc        → Launches Visual Studio Code (fuzzy match)
term       → Launches Terminal
```

### Running Commands

Type any shell command and press Enter:
```
git status
npm install
brew update
```

Commands that succeed (exit code 0) will close silently. Failed commands will show an error popup.

### Opening Directories

Type a path to see quick actions:
```
~/projects/myapp
```

Available actions:
- `⌘F` - Open in Finder
- `⌘T` - Open in Terminal
- `⌘C` - Open in Claude Code

### Tab Autocomplete

Press Tab to autocomplete paths:
```
~/Do[Tab] → ~/Documents/
~/Documents/pr[Tab] → ~/Documents/projects/
```

### Special Commands

- `cd <path>` - Opens terminal at the specified directory
- `!<command>` - Force show output even on success (future feature)

## Configuration

Configuration file is stored at `~/.morefastlight/config.json`

Edit this file to:
- Change keyboard shortcuts
- Add custom quick actions
- Modify terminal app preference (Terminal or iTerm2)
- Add custom app search paths

## Project Structure

```
Morefastlight/
├── MorefastlightApp.swift       # App entry point
├── Models/
│   ├── App.swift                # App data model
│   ├── Config.swift             # Configuration model
│   ├── QuickAction.swift        # Directory action model
│   ├── CommandResult.swift      # Command execution result
│   ├── PathEntry.swift          # Recent path tracking
│   └── SearchResult.swift       # Search result types
├── Views/
│   ├── SearchWindowController.swift  # Window management
│   ├── SearchWindow.swift            # Main search interface
│   ├── SearchField.swift             # Custom text field with keyboard handling
│   ├── SearchResultRow.swift         # Result display
│   ├── ErrorPopup.swift              # Command error display
│   └── SettingsView.swift            # Settings panel
├── Services/
│   ├── AppIndexer.swift         # App discovery & indexing
│   ├── AppCache.swift           # In-memory app cache
│   ├── CommandExecutor.swift    # Shell command execution
│   ├── PathAutocompleter.swift  # Tab completion logic
│   ├── ConfigManager.swift      # Config management
│   ├── InputClassifier.swift    # Input type detection
│   └── HotkeyManager.swift      # Global hotkey handling
├── Utilities/
│   └── FuzzySearch.swift        # Fuzzy matching algorithm
└── Info.plist                   # App configuration
```

## Troubleshooting

### Hotkey Not Working

- Make sure you've disabled Spotlight's `⌘Space` shortcut
- Check that the app has Accessibility permissions (System Settings → Privacy & Security → Accessibility)

### Apps Not Found

- Click the menu bar icon → "Reindex Apps"
- Check that `/Applications` and `~/Applications` are accessible

### Terminal Commands Failing

- Check that your shell path is correct in settings (default: `/bin/zsh`)
- Commands run in a non-interactive shell, so profile scripts may not load

## Development

### Running in Debug Mode

```bash
# Build from command line
xcodebuild -scheme Morefastlight -configuration Debug build

# Run from command line
xcodebuild -scheme Morefastlight -configuration Debug run
```

### Creating a Release Build

```bash
# Build release version
xcodebuild -scheme Morefastlight -configuration Release build

# The app will be in:
# build/Release/Morefastlight.app
```

## License

MIT License - Free to use, modify, and distribute.

## Credits

Built with Swift, SwiftUI, and AppKit for maximum performance and native macOS integration.
