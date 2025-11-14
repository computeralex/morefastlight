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
    let hotkeyManager = HotkeyManager()
    let appCache = AppCache.shared

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
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "bolt.fill", accessibilityDescription: "Morefastlight")
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
        NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func reindexApps() {
        Task {
            await appCache.rebuildIndex()
        }
    }
}
