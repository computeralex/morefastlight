import SwiftUI
import AppKit

struct SearchField: NSViewRepresentable {
    @Binding var query: String
    var onSubmit: () -> Void
    var onEscape: () -> Void
    var onTab: () -> Void
    var onShiftTab: () -> Void
    var onArrowUp: () -> Void
    var onArrowDown: () -> Void

    func makeNSView(context: Context) -> NSTextField {
        let textField = CustomTextField()
        textField.delegate = context.coordinator
        textField.placeholderString = "Search apps, run commands, or navigate paths..."
        textField.font = NSFont.systemFont(ofSize: 24, weight: .medium)
        textField.isBordered = false
        textField.focusRingType = .none
        textField.backgroundColor = .clear

        // Set the coordinator reference
        context.coordinator.textField = textField
        context.coordinator.onSubmit = onSubmit
        context.coordinator.onEscape = onEscape
        context.coordinator.onTab = onTab
        context.coordinator.onShiftTab = onShiftTab
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
        var onShiftTab: (() -> Void)?
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

        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            print("DEBUG: doCommandBy called with selector: \(commandSelector)")

            switch commandSelector {
            case #selector(NSResponder.insertNewline(_:)): // Return/Enter
                print("DEBUG: Return key detected, calling onSubmit")
                onSubmit?()
                return true

            case #selector(NSResponder.cancelOperation(_:)): // Escape
                print("DEBUG: Escape key detected, calling onEscape")
                onEscape?()
                return true

            case #selector(NSResponder.insertTab(_:)): // Tab
                print("DEBUG: Tab key detected, calling onTab")
                onTab?()
                return true

            case #selector(NSResponder.insertBacktab(_:)): // Shift+Tab
                print("DEBUG: Shift+Tab key detected, calling onShiftTab")
                onShiftTab?()
                return true

            case #selector(NSResponder.moveUp(_:)): // Up arrow
                print("DEBUG: Up arrow detected, calling onArrowUp")
                onArrowUp?()
                return true

            case #selector(NSResponder.moveDown(_:)): // Down arrow
                print("DEBUG: Down arrow detected, calling onArrowDown")
                onArrowDown?()
                return true

            default:
                print("DEBUG: Unhandled selector: \(commandSelector)")
                return false
            }
        }
    }

    class CustomTextField: NSTextField {
        override var acceptsFirstResponder: Bool {
            return true
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
