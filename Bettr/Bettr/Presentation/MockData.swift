import Foundation

// MARK: - Mock Data
// 뷰에서 사용하기 위한 Mock(가짜) 데이터입니다.

let MockData = ScriptData(
    title: "Script.pdf",
    sentences: [
        SentenceData(
            orderIndex: 0,
            englishText: "Hello world.",
            koreanText: "안녕 세상.",
            chunks: [
                ChunkData(orderIndex: 0, englishText: "Hello", koreanText: "안녕"),
                ChunkData(orderIndex: 1, englishText: "world", koreanText: "세상")
            ]
        ),
        SentenceData(
            orderIndex: 1,
            englishText: "How are you?",
            koreanText: "잘 지내?",
            chunks: [
                ChunkData(orderIndex: 0, englishText: "How", koreanText: "어떻게"),
                ChunkData(orderIndex: 1, englishText: "are", koreanText: "지내"),
                ChunkData(orderIndex: 2, englishText: "you", koreanText: "너")
            ]
        )
    ])
