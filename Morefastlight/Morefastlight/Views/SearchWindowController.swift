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

        print("DEBUG: showWindow called")

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

        print("DEBUG: Window is key? \(window.isKeyWindow)")
        print("DEBUG: App is active? \(NSApp.isActive)")

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

        // Give SwiftUI time to fully render, then focus with ONE strong attempt
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self, let window = self.window else { return }
            print("DEBUG: Attempting to focus text field...")
            print("DEBUG: Window is still key? \(window.isKeyWindow)")

            // Reactivate app and window to be absolutely sure
            NSApp.activate(ignoringOtherApps: true)
            window.makeKey()

            self.focusTextField(in: window.contentView)
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
        guard let view = view, let window = window else {
            print("DEBUG: No view or window in focusTextField")
            return
        }

        // Find NSTextField in subviews (recursively search the entire hierarchy)
        if let textField = view as? NSTextField {
            print("DEBUG: ✅ Found text field!")
            print("DEBUG: Text field can become first responder? \(textField.acceptsFirstResponder)")
            print("DEBUG: Window first responder before: \(String(describing: window.firstResponder))")

            // Make absolutely sure window is key
            window.makeKey()

            // Make text field first responder
            let success = window.makeFirstResponder(textField)
            print("DEBUG: makeFirstResponder returned: \(success)")
            print("DEBUG: Window first responder after: \(String(describing: window.firstResponder))")

            // Force becomeFirstResponder
            let becameFirst = textField.becomeFirstResponder()
            print("DEBUG: becomeFirstResponder returned: \(becameFirst)")

            // Select all text
            if let editor = textField.currentEditor() {
                editor.selectAll(nil)
                print("DEBUG: Selected all text in editor")
            } else {
                print("DEBUG: ⚠️ No current editor!")
            }

            return
        }

        for subview in view.subviews {
            focusTextField(in: subview)
        }
    }
}
