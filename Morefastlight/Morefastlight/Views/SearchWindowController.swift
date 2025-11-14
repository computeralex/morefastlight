import SwiftUI
import AppKit

class SearchWindowController: NSWindowController {
    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let searchView = SearchWindow()
        let hostingView = NSHostingView(rootView: searchView)
        window.contentView = hostingView

        self.init(window: window)
    }

    override func showWindow(_ sender: Any?) {
        guard let window = window else { return }

        // Center on screen
        if let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            let windowRect = window.frame
            let x = screenRect.midX - windowRect.width / 2
            let y = screenRect.midY - windowRect.height / 2 + 100 // Slightly above center
            window.setFrame(NSRect(x: x, y: y, width: windowRect.width, height: windowRect.height), display: true)
        }

        window.makeKeyAndOrderFront(sender)
        window.makeFirstResponder(window.contentView)
    }
}
