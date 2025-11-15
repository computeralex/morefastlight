import SwiftUI
import AppKit

class SettingsWindowController: NSWindowController {
    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 400),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )

        window.title = "Morefastlight Settings"
        window.center()

        let settingsView = SettingsView()
        let hostingView = NSHostingView(rootView: settingsView)
        window.contentView = hostingView

        self.init(window: window)
    }
}
