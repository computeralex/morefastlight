import Foundation

enum InputType {
    case appSearch
    case command
    case path
}

class InputClassifier {
    private let config: Config
    private let fileManager = FileManager.default

    init(config: Config = .default) {
        self.config = config
    }

    func classify(_ input: String) -> InputType {
        let trimmed = input.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return .appSearch }

        // Check if it's a path (even if incomplete)
        if trimmed.hasPrefix("/") || trimmed.hasPrefix("~") || trimmed.hasPrefix(".") || trimmed.hasPrefix("..") {
            return .path
        }

        // Check for command prefix
        for prefix in config.commandPrefixes {
            if trimmed.hasPrefix(prefix + " ") || trimmed == prefix {
                return .command
            }
        }

        // Default to app search
        return .appSearch
    }

    private func isPath(_ input: String) -> Bool {
        // Check for path indicators
        if input.hasPrefix("/") || input.hasPrefix("~") || input.hasPrefix(".") || input.hasPrefix("..") {
            let expandedPath = NSString(string: input).expandingTildeInPath
            return fileManager.fileExists(atPath: expandedPath)
        }
        return false
    }
}
