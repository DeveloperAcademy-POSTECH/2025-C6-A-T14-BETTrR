import BettrAI
import Foundation

extension SentenceData {
    init(sentence: Sentence, chunks: [ChunkData]) {
        self.init(
            orderIndex: sentence.orderIndex,
            englishText: sentence.englishText,
            koreanText: sentence.koreanText,
            chunks: chunks
        )
    }
}

extension ChunkData {
    init(chunk: Chunk) {
        self.init(
            orderIndex: chunk.orderIndex,
            englishText: chunk.englishText,
            koreanText: chunk.koreanText
        )
    }
}
