import Foundation

// MARK: - Mock Data
// 뷰에서 사용하기 위한 Mock(가짜) 데이터입니다.

let MockData = ScriptData(
    title: "Script.pdf",
    sentences: [
        SentenceData(
            orderIndex: 0,
            englishText: "This is sample text. It is for the data structure.",
            koreanText: "이것은 샘플 텍스트입니다. 데이터 구조를 위한 것입니다.",
            chunks: [
                ChunkData(orderIndex: 0, englishText: "This is", koreanText: "이것은"),
                ChunkData(orderIndex: 1, englishText: "sample text.", koreanText: "샘플 텍스트입니다."),
                ChunkData(orderIndex: 2, englishText: "It is", koreanText: "그것은"),
                ChunkData(orderIndex: 3, englishText: "for the", koreanText: "~를 위한 것입니다."),
                ChunkData(orderIndex: 4, englishText: "data", koreanText: "데이터"),
                ChunkData(orderIndex: 5, englishText: "structure.", koreanText: "구조")
            ]
        ),
        SentenceData(
            orderIndex: 1,
            englishText: "I am learning Swift programming.",
            koreanText: "저는 스위프트 프로그래밍을 배우고 있습니다.",
            chunks: [
                ChunkData(orderIndex: 0, englishText: "I am", koreanText: "저는"),
                ChunkData(orderIndex: 1, englishText: "learning", koreanText: "배우고 있습니다."),
                ChunkData(orderIndex: 2, englishText: "Swift", koreanText: "스위프트"),
                ChunkData(orderIndex: 3, englishText: "programming.", koreanText: "프로그래밍을.")
            ]
        ),
        
        SentenceData(
            orderIndex: 2,
            englishText: "What is your favorite food?",
            koreanText: "가장 좋아하는 음식이 무엇인가요?",
            chunks: [
                ChunkData(orderIndex: 0, englishText: "What is", koreanText: "무엇인가요?"),
                ChunkData(orderIndex: 1, englishText: "your favorite", koreanText: "가장 좋아하는"),
                ChunkData(orderIndex: 2, englishText: "food?", koreanText: "음식이?")
            ]
        ),
        
        SentenceData(
            orderIndex: 3,
            englishText: "Please check your network connection.",
            koreanText: "네트워크 연결을 확인해주세요.",
            chunks: [
                ChunkData(orderIndex: 0, englishText: "Please check", koreanText: "확인해주세요."),
                ChunkData(orderIndex: 1, englishText: "your network", koreanText: "네트워크"),
                ChunkData(orderIndex: 2, englishText: "connection.", koreanText: "연결을.")
            ]
        ),
        
        SentenceData(
            orderIndex: 4,
            englishText: "Speech recognition accuracy depends on the microphone quality.",
            koreanText: "음성 인식 정확도는 마이크 품질에 따라 달라집니다.",
            chunks: [
                ChunkData(orderIndex: 0, englishText: "Speech recognition", koreanText: "음성 인식"),
                ChunkData(orderIndex: 1, englishText: "accuracy", koreanText: "정확도는"),
                ChunkData(orderIndex: 2, englishText: "depends on", koreanText: "달라집니다."),
                ChunkData(orderIndex: 3, englishText: "the microphone", koreanText: "마이크"),
                ChunkData(orderIndex: 4, englishText: "quality.", koreanText: "품질에 따라.")
            ]
        ),
        
        SentenceData(
            orderIndex: 5,
            englishText: "Tap the button to start recording.",
            koreanText: "버튼을 탭하여 녹음을 시작하세요.",
            chunks: [
                ChunkData(orderIndex: 0, englishText: "Tap the button", koreanText: "버튼을 탭하여"),
                ChunkData(orderIndex: 1, englishText: "to start", koreanText: "시작하세요."),
                ChunkData(orderIndex: 2, englishText: "recording.", koreanText: "녹음을.")
            ]
        )
    ])
