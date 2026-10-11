import Foundation

nonisolated public struct SentenceData: Codable, Hashable, Sendable {
    public var orderIndex: Int
    public var englishText: String
    public var koreanText: String
    public var chunks: [ChunkData]

    public init(orderIndex: Int, englishText: String, koreanText: String, chunks: [ChunkData]) {
        self.orderIndex = orderIndex
        self.englishText = englishText
        self.koreanText = koreanText
        self.chunks = chunks
    }
}
