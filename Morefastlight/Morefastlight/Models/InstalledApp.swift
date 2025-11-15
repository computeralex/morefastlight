import Foundation

enum AppType: String, Codable {
    case app
    case pwa
    case system
}

struct InstalledApp: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let path: String
    let type: AppType
    let keywords: [String]
    var lastUsed: Date?
    var useCount: Int

    init(name: String, path: String, type: AppType = .app) {
        self.id = UUID()
        self.name = name
        self.path = path
        self.type = type
        self.keywords = Self.generateKeywords(from: name)
        self.lastUsed = nil
        self.useCount = 0
    }

    static func generateKeywords(from name: String) -> [String] {
        var keywords: [String] = []

        // Add full name
        keywords.append(name.lowercased())

        // Remove common suffixes
        let cleanName = name.replacingOccurrences(of: ".app", with: "")

        // Add words
        let words = cleanName.components(separatedBy: CharacterSet.alphanumerics.inverted)
        keywords.append(contentsOf: words.map { $0.lowercased() }.filter { !$0.isEmpty })

        // Add acronym
        let acronym = words.compactMap { $0.first }.map { String($0).lowercased() }.joined()
        if !acronym.isEmpty {
            keywords.append(acronym)
        }

        return Array(Set(keywords))
    }
}
