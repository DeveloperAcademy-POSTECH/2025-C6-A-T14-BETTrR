import Foundation

nonisolated public struct ScriptData: Codable, Hashable, Sendable {
    public var title: String
    public var sentences: [SentenceData]

    public init(title: String, sentences: [SentenceData]) {
        self.title = title
        self.sentences = sentences
    }
}
