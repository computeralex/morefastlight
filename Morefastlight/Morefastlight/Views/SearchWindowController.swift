import SwiftUI
import AppKit

class KeyableWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    override func resignKey() {
        super.resignKey()
        // Close window when it loses key status (e.g., clicking outside)
        close()
    }
}

class SearchWindowController: NSWindowController, NSWindowDelegate {
    private var clickMonitor: Any?

    convenience init() {
        let window = KeyableWindow(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 500),
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isMovableByWindowBackground = true

        self.init(window: window)
        window.delegate = self
    }

    deinit {
        if let monitor = clickMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    override func showWindow(_ sender: Any?) {
        guard let window = window else { return }

        // Recreate the content view each time to ensure fresh state
        let searchView = SearchWindow()
        let hostingView = NSHostingView(rootView: searchView)
        window.contentView = hostingView

        // Center on screen
        if let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            let windowRect = window.frame
            let x = screenRect.midX - windowRect.width / 2
            let y = screenRect.midY - windowRect.height / 2 + 100 // Slightly above center
            window.setFrame(NSRect(x: x, y: y, width: windowRect.width, height: windowRect.height), display: true)
        }

        // Make window visible first
        window.makeKeyAndOrderFront(sender)

        // THEN activate the app - this is critical after Terminal has taken focus
        NSApp.activate(ignoringOtherApps: true)

        // Make sure window is key again after activation
        window.makeKey()

        // Install click monitor to close window when clicking outside
        if clickMonitor == nil {
            clickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
                guard let self = self, let window = self.window else { return }

                let clickLocation = NSEvent.mouseLocation
                if !window.frame.contains(clickLocation) {
                    window.close()
                }
            }
        }

        // Try to focus immediately and keep trying until it works
        // This minimizes the "boop boop" sound from rejected keystrokes
        for delay in [0.0, 0.05, 0.1, 0.15] {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self = self, let window = self.window else { return }

                // Only try if we don't already have a responder
                if window.firstResponder == nil || window.firstResponder === window {
                    NSApp.activate(ignoringOtherApps: true)
                    window.makeKey()
                    self.focusTextField(in: window.contentView)
                }
            }
        }
    }

    func windowWillClose(_ notification: Notification) {
        // Remove click monitor when window closes
        if let monitor = clickMonitor {
            NSEvent.removeMonitor(monitor)
            clickMonitor = nil
        }
    }

    private func focusTextField(in view: NSView?) {
        guard let view = view, let window = window else { return }

        // Find NSTextField in subviews (recursively search the entire hierarchy)
        if let textField = view as? NSTextField {
            // Make absolutely sure window is key
            window.makeKey()

            // Make text field first responder
            window.makeFirstResponder(textField)

            // Force becomeFirstResponder
            textField.becomeFirstResponder()

            // Select all text
            textField.currentEditor()?.selectAll(nil)

            return
        }

        for subview in view.subviews {
            focusTextField(in: subview)
        }
    }
}
