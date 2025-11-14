import Foundation

class PathAutocompleter {
    private let fileManager = FileManager.default

    func autocomplete(_ input: String) -> [String] {
        let expandedPath = NSString(string: input).expandingTildeInPath
        let directory = (expandedPath as NSString).deletingLastPathComponent
        let prefix = (expandedPath as NSString).lastPathComponent

        guard fileManager.fileExists(atPath: directory) else { return [] }

        do {
            let contents = try fileManager.contentsOfDirectory(atPath: directory)
            let matches = contents.filter { item in
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
