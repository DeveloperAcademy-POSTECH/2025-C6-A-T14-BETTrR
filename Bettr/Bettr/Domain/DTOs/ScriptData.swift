import Foundation

struct ScriptData: Codable, Hashable {
    var title: String
    var sentences: [SentenceData]
}
