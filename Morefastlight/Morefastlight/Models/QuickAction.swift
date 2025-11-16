import Foundation

struct QuickAction: Codable, Identifiable, Hashable {
    let id: String
    var name: String
    var commandTemplate: String
    var shortcut: String
    var icon: String
    var enabled: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case commandTemplate = "command_template"
        case shortcut
        case icon
        case enabled
    }

    func executeCommand(path: String, terminalApp: String, shell: String) -> String {
        // SECURITY: Escape path for AppleScript if command contains "tell application"
        let escapedPath: String
        if commandTemplate.contains("tell application") {
            escapedPath = escapeAppleScriptString(path)
        } else {
            // For shell commands, escape single quotes
            escapedPath = path.replacingOccurrences(of: "'", with: "'\\''")
        }

        return commandTemplate
            .replacingOccurrences(of: "{path}", with: escapedPath)
            .replacingOccurrences(of: "{terminal_app}", with: terminalApp)
            .replacingOccurrences(of: "{shell}", with: shell)
    }

    // SECURITY: Escape strings for AppleScript to prevent injection attacks
    private func escapeAppleScriptString(_ str: String) -> String {
        return str
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
    }
}
