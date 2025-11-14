import SwiftUI
import AppKit

struct SearchField: NSViewRepresentable {
    @Binding var query: String
    var onSubmit: () -> Void
    var onEscape: () -> Void
    var onTab: () -> Void
    var onArrowUp: () -> Void
    var onArrowDown: () -> Void

    func makeNSView(context: Context) -> NSTextField {
        let textField = CustomTextField()
        textField.delegate = context.coordinator
        textField.placeholderString = "Search apps, run commands, or navigate paths..."
        textField.font = NSFont.systemFont(ofSize: 18)
        textField.isBordered = false
        textField.focusRingType = .none
        textField.backgroundColor = .clear

        // Set the coordinator reference
        context.coordinator.textField = textField
        context.coordinator.onSubmit = onSubmit
        context.coordinator.onEscape = onEscape
        context.coordinator.onTab = onTab
        context.coordinator.onArrowUp = onArrowUp
        context.coordinator.onArrowDown = onArrowDown

        return textField
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        nsView.stringValue = query
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(query: $query)
    }

    class Coordinator: NSObject, NSTextFieldDelegate {
        @Binding var query: String
        var textField: NSTextField?
        var onSubmit: (() -> Void)?
        var onEscape: (() -> Void)?
        var onTab: (() -> Void)?
        var onArrowUp: (() -> Void)?
        var onArrowDown: (() -> Void)?

        init(query: Binding<String>) {
            _query = query
        }

        func controlTextDidChange(_ obj: Notification) {
            if let textField = obj.object as? NSTextField {
                query = textField.stringValue
            }
        }

        @objc func handleKeyDown(_ event: NSEvent) -> Bool {
            switch Int(event.keyCode) {
            case 36: // Return
                onSubmit?()
                return true
            case 53: // Escape
                onEscape?()
                return true
            case 48: // Tab
                onTab?()
                return true
            case 126: // Up arrow
                onArrowUp?()
                return true
            case 125: // Down arrow
                onArrowDown?()
                return true
            default:
                return false
            }
        }
    }

    class CustomTextField: NSTextField {
        override func keyDown(with event: NSEvent) {
            if let coordinator = delegate as? Coordinator,
               coordinator.handleKeyDown(event) {
                return
            }
            super.keyDown(with: event)
        }

        override func becomeFirstResponder() -> Bool {
            let result = super.becomeFirstResponder()
            // Select all text when field becomes first responder
            DispatchQueue.main.async {
                self.currentEditor()?.selectAll(nil)
            }
            return result
        }
    }
}
