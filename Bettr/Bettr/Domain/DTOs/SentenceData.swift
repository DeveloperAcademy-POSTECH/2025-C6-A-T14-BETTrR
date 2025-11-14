import Foundation

struct SentenceData: Codable, Hashable {
    var orderIndex: Int
    var englishText: String
    var koreanText: String
    var chunks: [ChunkData]
    
    init(sentence: Sentence, chunks: [ChunkData]) {
        self.orderIndex = sentence.orderIndex
        self.englishText = sentence.englishText
        self.koreanText = sentence.koreanText
        self.chunks = chunks
    }
    
    // 데모 데이터 생성용 생성자
    init(orderIndex: Int, englishText: String, koreanText: String, chunks: [ChunkData]) {
        self.orderIndex = orderIndex
        self.englishText = englishText
        self.koreanText = koreanText
        self.chunks = chunks
    }
}
