import Foundation

class AppIndexer {
    private let fileManager = FileManager.default
    private let config: Config

    init(config: Config = .default) {
        self.config = config
    }

    func buildIndex() async -> [App] {
        var apps: [App] = []

        for searchPath in config.appSearchPaths {
            let expandedPath = NSString(string: searchPath).expandingTildeInPath
            let foundApps = await scanDirectory(at: expandedPath)
            apps.append(contentsOf: foundApps)
        }

        // Remove duplicates based on path
        var uniqueApps: [String: App] = [:]
        for app in apps {
            uniqueApps[app.path] = app
        }

        return Array(uniqueApps.values).sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private func scanDirectory(at path: String, depth: Int = 0, maxDepth: Int = 2) async -> [App] {
        guard depth <= maxDepth else { return [] }
        guard fileManager.fileExists(atPath: path) else { return [] }

        var apps: [App] = []

        do {
            let contents = try fileManager.contentsOfDirectory(atPath: path)

            for item in contents {
                let itemPath = (path as NSString).appendingPathComponent(item)

                var isDirectory: ObjCBool = false
                guard fileManager.fileExists(atPath: itemPath, isDirectory: &isDirectory) else { continue }

                if item.hasSuffix(".app") {
                    // Found an application
                    let appName = item.replacingOccurrences(of: ".app", with: "")
                    let appType: AppType = determineAppType(path: path)
                    let app = App(name: appName, path: itemPath, type: appType)
                    apps.append(app)
                } else if isDirectory.boolValue && !item.hasPrefix(".") {
                    // Recurse into subdirectory
                    let subApps = await scanDirectory(at: itemPath, depth: depth + 1, maxDepth: maxDepth)
                    apps.append(contentsOf: subApps)
                }
            }
        } catch {
            print("Error scanning directory \(path): \(error)")
        }

        return apps
    }

    private func determineAppType(path: String) -> AppType {
        if path.contains("/System/Applications") {
            return .system
        } else if path.contains("Chrome Apps") || path.contains("Brave Apps") {
            return .pwa
        } else {
            return .app
        }
    }
}
