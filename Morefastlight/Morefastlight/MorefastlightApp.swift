import SwiftUI

@main
struct MorefastlightApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        Settings {
            SettingsView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var searchWindowController: SearchWindowController?
    var settingsWindowController: SettingsWindowController?
    let hotkeyManager = HotkeyManager()
    let appCache = AppCache.shared
    var reindexTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Setup menu bar icon
        setupMenuBar()

        // Register global hotkey
        hotkeyManager.register { [weak self] in
            self?.showSearch()
        }

        // Load app index in background
        Task {
            await appCache.loadAppIndex()
        }

        // Set up periodic reindexing (every 24 hours)
        startPeriodicReindexing()
    }

    func startPeriodicReindexing() {
        // Load config to get reindex interval
        let configManager = ConfigManager()
        let intervalSeconds = TimeInterval(configManager.config.reindexIntervalHours * 3600)

        reindexTimer = Timer.scheduledTimer(withTimeInterval: intervalSeconds, repeats: true) { [weak self] _ in
            print("Periodic reindexing...")
            Task {
                await self?.appCache.rebuildIndex()
            }
        }
    }

    deinit {
        reindexTimer?.invalidate()
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            // Load custom rocket icon
            if let iconPath = Bundle.main.path(forResource: "icon", ofType: "png"),
               let iconImage = NSImage(contentsOfFile: iconPath) {
                iconImage.isTemplate = true // Makes it adapt to light/dark mode
                iconImage.size = NSSize(width: 18, height: 18)
                button.image = iconImage
            } else {
                // Fallback to SF Symbol if custom icon not found
                button.image = NSImage(systemSymbolName: "bolt.fill", accessibilityDescription: "Morefastlight")
            }
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Search...", action: #selector(showSearch), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(showSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: "Reindex Apps", action: #selector(reindexApps), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        statusItem?.menu = menu
    }

    @objc func showSearch() {
        if searchWindowController == nil {
            searchWindowController = SearchWindowController()
        }
        searchWindowController?.showWindow(nil)
        searchWindowController?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func showSettings() {
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController()
        }
        settingsWindowController?.showWindow(nil)
        settingsWindowController?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func reindexApps() {
        Task {
            await appCache.rebuildIndex()
        }
    }
}
