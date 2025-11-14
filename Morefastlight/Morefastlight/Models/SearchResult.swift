import Foundation

enum SearchResult: Identifiable, Hashable {
    case app(App)
    case directoryAction(DirectoryAction)
    case command(String)

    var id: String {
        switch self {
        case .app(let app):
            return "app-\(app.id)"
        case .directoryAction(let action):
            return "dir-\(action.id)"
        case .command(let cmd):
            return "cmd-\(cmd)"
        }
    }
}

struct DirectoryAction: Identifiable, Hashable {
    let id: String
    let name: String
    let path: String
    let icon: String
    let shortcut: String?
    let action: () -> Void

    init(id: String, name: String, path: String, icon: String, shortcut: String? = nil, action: @escaping () -> Void) {
        self.id = id
        self.name = name
        self.path = path
        self.icon = icon
        self.shortcut = shortcut
        self.action = action
    }

    static func == (lhs: DirectoryAction, rhs: DirectoryAction) -> Bool {
        lhs.id == rhs.id && lhs.path == rhs.path
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(path)
    }
}
