import Foundation

struct ChunkData: Codable, Hashable {
    var orderIndex: Int
    var englishText: String
    var koreanText: String
    
    init(chunk: Chunk) {
        self.orderIndex = chunk.orderIndex
        self.englishText = chunk.englishText
        self.koreanText = chunk.koreanText
    }
    
    // 데모 데이터 생성용 생성자
    init(orderIndex: Int, englishText: String, koreanText: String) {
        self.orderIndex = orderIndex
        self.englishText = englishText
        self.koreanText = koreanText
    }
}
