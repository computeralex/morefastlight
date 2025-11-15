import Foundation

struct AppIndexCache: Codable {
    let version: String
    let apps: [InstalledApp]
    let timestamp: Date
}

actor AppCache {
    static let shared = AppCache()

    private var apps: [InstalledApp] = []
    private var config: Config = .default
    private let cacheURL: URL

    private init() {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        let morefastlightDir = homeDir.appendingPathComponent(".morefastlight")
        try? FileManager.default.createDirectory(at: morefastlightDir, withIntermediateDirectories: true)
        self.cacheURL = morefastlightDir.appendingPathComponent("app_index.cache")
    }

    func loadAppIndex() async {
        // Try to load from cache first
        if let cache = loadFromCache(), isCacheValid(cache) {
            apps = cache.apps
            print("Loaded \(apps.count) apps from cache")
        } else {
            // Build fresh index
            await rebuildIndex()
        }
    }

    func rebuildIndex() async {
        print("Building app index...")
        let indexer = AppIndexer(config: config)
        apps = await indexer.buildIndex()
        saveToCache()
        print("Indexed \(apps.count) apps")
    }

    func search(_ query: String) async -> [InstalledApp] {
        guard !query.isEmpty else { return Array(apps.prefix(config.ui.maxResults)) }

        let fuzzySearch = FuzzySearch()
        let results = fuzzySearch.search(query: query, in: apps, maxResults: config.ui.maxResults)
        return results
    }

    func getApp(at index: Int) async -> InstalledApp? {
        guard index >= 0 && index < apps.count else { return nil }
        return apps[index]
    }

    func recordAppLaunch(_ app: InstalledApp) async {
        if let index = apps.firstIndex(where: { $0.id == app.id }) {
            apps[index].useCount += 1
            apps[index].lastUsed = Date()
            saveToCache()
        }
    }

    private func loadFromCache() -> AppIndexCache? {
        guard FileManager.default.fileExists(atPath: cacheURL.path) else { return nil }

        do {
            let data = try Data(contentsOf: cacheURL)
            let cache = try JSONDecoder().decode(AppIndexCache.self, from: data)
            return cache
        } catch {
            print("Failed to load cache: \(error)")
            return nil
        }
    }

    private func saveToCache() {
        let cache = AppIndexCache(
            version: "1.0",
            apps: apps,
            timestamp: Date()
        )

        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(cache)
            try data.write(to: cacheURL)
        } catch {
            print("Failed to save cache: \(error)")
        }
    }

    private func isCacheValid(_ cache: AppIndexCache) -> Bool {
        // Cache is valid if less than 24 hours old
        let ageInSeconds = Date().timeIntervalSince(cache.timestamp)
        return ageInSeconds < 86400
    }
}
