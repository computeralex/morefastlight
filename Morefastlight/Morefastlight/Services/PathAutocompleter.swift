import Foundation

class PathAutocompleter {
    private let fileManager = FileManager.default

    // SECURITY: Validate that path is safe to access
    private func validatePath(_ path: String) -> Bool {
        let expandedPath = NSString(string: path).expandingTildeInPath

        // Disallow sensitive system directories
        let forbidden = [
            "/etc/", "/var/", "/private/", "/System/Library/",
            "/.ssh/", "/.gnupg/", "/Library/Keychains/"
        ]

        for prefix in forbidden {
            if expandedPath.hasPrefix(prefix) {
                return false
            }
        }

        // Only allow user's home directory, /Applications, and /Users
        let homeDir = fileManager.homeDirectoryForCurrentUser.path
        let allowed = [homeDir, "/Applications", "/Users"]

        return allowed.contains { expandedPath.hasPrefix($0) }
    }

    func autocomplete(_ input: String) -> [String] {
        let expandedPath = NSString(string: input).expandingTildeInPath

        // If input ends with /, we want to list all items IN that directory
        let directory: String
        let prefix: String

        if input.hasSuffix("/") {
            directory = expandedPath
            prefix = ""
        } else {
            directory = (expandedPath as NSString).deletingLastPathComponent
            prefix = (expandedPath as NSString).lastPathComponent
        }

        // SECURITY: Validate path before accessing
        guard validatePath(directory) else {
            print("⚠️ Security: Blocked autocomplete for sensitive path: \(directory)")
            return []
        }

        guard fileManager.fileExists(atPath: directory) else { return [] }

        do {
            let contents = try fileManager.contentsOfDirectory(atPath: directory)
            let matches = contents.filter { item in
                // Skip hidden files (starting with .)
                !item.hasPrefix(".") &&
                item.lowercased().hasPrefix(prefix.lowercased()) &&
                isDirectory("\(directory)/\(item)")
            }.sorted()

            // Convert back to the original format (with ~ if applicable)
            return matches.map { match in
                let fullPath = (directory as NSString).appendingPathComponent(match)
                if input.hasPrefix("~") {
                    let homeDir = fileManager.homeDirectoryForCurrentUser.path
                    if fullPath.hasPrefix(homeDir) {
                        return fullPath.replacingOccurrences(of: homeDir, with: "~")
                    }
                }
                return fullPath
            }
        } catch {
            return []
        }
    }

    func completeNext(_ input: String, currentCompletion: String?) -> String? {
        let matches = autocomplete(input)

        guard !matches.isEmpty else { return nil }

        if let current = currentCompletion,
           let currentIndex = matches.firstIndex(of: current) {
            let nextIndex = (currentIndex + 1) % matches.count
            return matches[nextIndex]
        }

        return matches.first
    }

    private func isDirectory(_ path: String) -> Bool {
        var isDir: ObjCBool = false
        fileManager.fileExists(atPath: path, isDirectory: &isDir)
        return isDir.boolValue
    }
}
