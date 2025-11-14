import Foundation
import Combine

class ConfigManager: ObservableObject {
    @Published var config: Config

    private let configURL: URL
    private let fileManager = FileManager.default

    init() {
        let homeDir = fileManager.homeDirectoryForCurrentUser
        let morefastlightDir = homeDir.appendingPathComponent(".morefastlight")

        // Create directory if it doesn't exist
        try? fileManager.createDirectory(at: morefastlightDir, withIntermediateDirectories: true)

        configURL = morefastlightDir.appendingPathComponent("config.json")

        // Load config or create default
        if let loadedConfig = Self.loadConfig(from: configURL) {
            self.config = loadedConfig
        } else {
            self.config = .default
            Self.saveConfig(config, to: configURL)
        }
    }

    func save() {
        Self.saveConfig(config, to: configURL)
    }

    func reset() {
        config = .default
        save()
    }

    private static func loadConfig(from url: URL) -> Config? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            return try decoder.decode(Config.self, from: data)
        } catch {
            print("Failed to load config: \(error)")
            return nil
        }
    }

    private static func saveConfig(_ config: Config, to url: URL) {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(config)
            try data.write(to: url)
        } catch {
            print("Failed to save config: \(error)")
        }
    }
}
