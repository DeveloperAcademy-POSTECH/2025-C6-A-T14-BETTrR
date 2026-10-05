import Foundation

nonisolated struct ChunkData: Codable, Hashable, Sendable {
    var orderIndex: Int
    var englishText: String
    var koreanText: String
}
