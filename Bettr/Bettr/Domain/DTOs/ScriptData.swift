import Foundation

struct ScriptData: Codable, Hashable, Sendable {
    var title: String
    var sentences: [SentenceData]
}
