import Foundation

struct PathEntry: Codable {
    var path: String
    var frequency: Int
    var lastAccessed: Date

    enum CodingKeys: String, CodingKey {
        case path
        case frequency
        case lastAccessed = "last_accessed"
    }

    init(path: String) {
        self.path = path
        self.frequency = 1
        self.lastAccessed = Date()
    }

    mutating func incrementUsage() {
        self.frequency += 1
        self.lastAccessed = Date()
    }

    var score: Double {
        let daysSinceAccess = Date().timeIntervalSince(lastAccessed) / 86400
        let recencyScore = exp(-daysSinceAccess / 30) // Decay over 30 days
        return Double(frequency) * recencyScore
    }
}
