import Foundation

class FuzzySearch {
    func search(query: String, in apps: [InstalledApp], maxResults: Int = 8) -> [InstalledApp] {
        let lowerQuery = query.lowercased()

        // Score each app
        let scoredApps = apps.compactMap { app -> (InstalledApp, Double)? in
            guard let score = calculateScore(query: lowerQuery, app: app) else { return nil }
            return (app, score)
        }

        // Sort by score (higher is better)
        let sorted = scoredApps.sorted { $0.1 > $1.1 }

        // Return top results
        return sorted.prefix(maxResults).map { $0.0 }
    }

    private func calculateScore(query: String, app: InstalledApp) -> Double? {
        let appName = app.name.lowercased()

        // Exact match
        if appName == query {
            return 1000.0
        }

        // Starts with query
        if appName.hasPrefix(query) {
            return 900.0 + Double(100 - query.count)
        }

        // Contains query as substring
        if appName.contains(query) {
            return 800.0
        }

        // Check keywords
        for keyword in app.keywords {
            if keyword == query {
                return 700.0
            }
            if keyword.hasPrefix(query) {
                return 600.0
            }
            if keyword.contains(query) {
                return 500.0
            }
        }

        // Fuzzy character matching
        if let fuzzyScore = fuzzyMatch(query: query, target: appName) {
            return fuzzyScore
        }

        return nil
    }

    private func fuzzyMatch(query: String, target: String) -> Double? {
        var queryIndex = query.startIndex
        var matchCount = 0
        var consecutiveMatches = 0
        var lastMatchIndex = -1

        for (targetIndex, char) in target.enumerated() {
            guard queryIndex < query.endIndex else { break }

            if char == query[queryIndex] {
                matchCount += 1
                if targetIndex == lastMatchIndex + 1 {
                    consecutiveMatches += 1
                } else {
                    consecutiveMatches = 1
                }
                lastMatchIndex = targetIndex
                queryIndex = query.index(after: queryIndex)
            }
        }

        // All characters must match
        guard queryIndex == query.endIndex else { return nil }

        // Score based on match ratio and consecutive matches
        let matchRatio = Double(matchCount) / Double(target.count)
        let consecutiveBonus = Double(consecutiveMatches) * 10
        return (matchRatio * 100) + consecutiveBonus
    }
}
