import Foundation

nonisolated struct SentenceData: Codable, Hashable, Sendable {
    var orderIndex: Int
    var englishText: String
    var koreanText: String
    var chunks: [ChunkData]
}
