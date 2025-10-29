import Foundation

struct SentenceData: Codable, Hashable {
    var orderIndex: Int
    var englishText: String
    var koreanText: String
    var chunks: [ChunkData]
}
