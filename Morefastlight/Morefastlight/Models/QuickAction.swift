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
        return commandTemplate
            .replacingOccurrences(of: "{path}", with: path)
            .replacingOccurrences(of: "{terminal_app}", with: terminalApp)
            .replacingOccurrences(of: "{shell}", with: shell)
    }
}
