import Foundation

extension SentenceData {
    init(sentence: Sentence, chunks: [ChunkData]) {
        self.orderIndex = sentence.orderIndex
        self.englishText = sentence.englishText
        self.koreanText = sentence.koreanText
        self.chunks = chunks
    }
}

extension ChunkData {
    init(chunk: Chunk) {
        self.orderIndex = chunk.orderIndex
        self.englishText = chunk.englishText
        self.koreanText = chunk.koreanText
    }
}
