
import Foundation
import GRDB

struct DemoDataGenerator {
    static func generate(into database: AppDatabase) async throws {
        let scriptRepository = ScriptRepository(dbQueue: database.dbQueue)
        let scriptManagementService = ScriptManagementService(scriptRepository: scriptRepository)
        
        // Check if demo data already exists to prevent duplicates
        let existingScripts = try await scriptManagementService.fetchAllScripts()
        if !existingScripts.isEmpty {
            print("ℹ️ Demo data already exists. Skipping creation.")
            return
        }
        
        let demoScriptData: [ScriptData] = [
            ScriptData(
                title: "TravelGuide.pdf",
                sentences: [
                    SentenceData(
                        orderIndex: 0,
                        englishText: "Where is the nearest subway station?",
                        koreanText: "가장 가까운 지하철역이 어디인가요?",
                        chunks: [
                            ChunkData(orderIndex: 0, englishText: "Where is", koreanText: "어디인가요?"),
                            ChunkData(orderIndex: 1, englishText: "the nearest", koreanText: "가장 가까운"),
                            ChunkData(orderIndex: 2, englishText: "subway station?", koreanText: "지하철역이?")
                        ]
                    ),
                    SentenceData(
                        orderIndex: 1,
                        englishText: "I would like to buy a ticket to Paris.",
                        koreanText: "파리행 티켓을 한 장 사고 싶습니다.",
                        chunks: [
                            ChunkData(orderIndex: 0, englishText: "I would like to buy", koreanText: "사고 싶습니다."),
                            ChunkData(orderIndex: 1, englishText: "a ticket", koreanText: "티켓을 한 장"),
                            ChunkData(orderIndex: 2, englishText: "to Paris.", koreanText: "파리행.")
                        ]
                    ),
                    SentenceData(
                        orderIndex: 2,
                        englishText: "Have a safe trip!",
                        koreanText: "안전한 여행 되세요!",
                        chunks: [
                            ChunkData(orderIndex: 0, englishText: "Have a", koreanText: "되세요!"),
                            ChunkData(orderIndex: 1, englishText: "safe trip!", koreanText: "안전한 여행")
                        ]
                    )
                ]),
            ScriptData(
                title: "DailyConversation.txt",
                sentences: [
                    SentenceData(
                        orderIndex: 0,
                        englishText: "What time is it now?",
                        koreanText: "지금 몇 시예요?",
                        chunks: [
                            ChunkData(orderIndex: 0, englishText: "What time", koreanText: "몇 시예요?"),
                            ChunkData(orderIndex: 1, englishText: "is it now?", koreanText: "지금")
                        ]
                    ),
                    SentenceData(
                        orderIndex: 1,
                        englishText: "I am feeling hungry.",
                        koreanText: "배가 고프네요.",
                        chunks: [
                            ChunkData(orderIndex: 0, englishText: "I am", koreanText: ""),
                            ChunkData(orderIndex: 1, englishText: "feeling hungry.", koreanText: "배가 고프네요.")
                        ]
                    ),
                    SentenceData(
                        orderIndex: 2,
                        englishText: "Let's go for a walk in the park.",
                        koreanText: "공원에 산책하러 갑시다.",
                        chunks: [
                            ChunkData(orderIndex: 0, englishText: "Let's go", koreanText: "갑시다."),
                            ChunkData(orderIndex: 1, englishText: "for a walk", koreanText: "산책하러"),
                            ChunkData(orderIndex: 2, englishText: "in the park.", koreanText: "공원에.")
                        ]
                    )
                ]),
            ScriptData(
                title: "TechTalk.md",
                sentences: [
                    SentenceData(
                        orderIndex: 0,
                        englishText: "This new update includes many features.",
                        koreanText: "이번 새 업데이트는 많은 기능을 포함합니다.",
                        chunks: [
                            ChunkData(orderIndex: 0, englishText: "This new update", koreanText: "이번 새 업데이트는"),
                            ChunkData(orderIndex: 1, englishText: "includes", koreanText: "포함합니다."),
                            ChunkData(orderIndex: 2, englishText: "many features.", koreanText: "많은 기능을.")
                        ]
                    ),
                    SentenceData(
                        orderIndex: 1,
                        englishText: "My computer is running very slowly.",
                        koreanText: "제 컴퓨터가 매우 느리게 작동하네요.",
                        chunks: [
                            ChunkData(orderIndex: 0, englishText: "My computer is", koreanText: "제 컴퓨터가"),
                            ChunkData(orderIndex: 1, englishText: "running", koreanText: "작동하네요."),
                            ChunkData(orderIndex: 2, englishText: "very slowly.", koreanText: "매우 느리게.")
                        ]
                    )
                ]),
            ScriptData(
                title: "WeatherForecast.pdf",
                sentences: [
                    SentenceData(
                        orderIndex: 0,
                        englishText: "It looks like it will rain today.",
                        koreanText: "오늘 비가 올 것 같습니다.",
                        chunks: [
                            ChunkData(orderIndex: 0, englishText: "It looks like", koreanText: "같습니다."),
                            ChunkData(orderIndex: 1, englishText: "it will rain", koreanText: "비가 올 것"),
                            ChunkData(orderIndex: 2, englishText: "today.", koreanText: "오늘.")
                        ]
                    ),
                    SentenceData(
                        orderIndex: 1,
                        englishText: "Don't forget to take your umbrella.",
                        koreanText: "우산 챙기는 것 잊지 마세요.",
                        chunks: [
                            ChunkData(orderIndex: 0, englishText: "Don't forget", koreanText: "잊지 마세요."),
                            ChunkData(orderIndex: 1, englishText: "to take", koreanText: "챙기는 것"),
                            ChunkData(orderIndex: 2, englishText: "your umbrella.", koreanText: "우산.")
                        ]
                    ),
                    SentenceData(
                        orderIndex: 2,
                        englishText: "The weather is very sunny and warm.",
                        koreanText: "날씨가 매우 화창하고 따뜻합니다.",
                        chunks: [
                            ChunkData(orderIndex: 0, englishText: "The weather is", koreanText: "날씨가"),
                            ChunkData(orderIndex: 1, englishText: "very sunny", koreanText: "매우 화창하고"),
                            ChunkData(orderIndex: 2, englishText: "and warm.", koreanText: "따뜻합니다.")
                        ]
                    )
                ]),
            ScriptData(
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
        ]
        
        for (index, scriptData) in demoScriptData.enumerated() {
            let script = try await scriptManagementService.createScript(scriptData: scriptData)
            guard let scriptId = script.id else { continue }
            
            let feedbackDetailsData: [(wordDiff: WordDiff, originalText: String?, sentenceIndex: Int, wordIndex: Int)] = [
                (wordDiff: .missing(expected: "preview"), originalText: "preview", sentenceIndex: 0, wordIndex: 0),
                (wordDiff: .extra(actual: "extra"), originalText: nil, sentenceIndex: 0, wordIndex: 1)
            ]
            
            _ = try await scriptManagementService.createFeedbackSummary(
                scriptId: scriptId,
                accuracy: (60.0 + Double(index * 10)) / 100.0, // Convert to accuracy (0.0 - 1.0)
                missingWordCount: 1,
                addedWordCount: 1,
                replacedWordCount: 0,
                practiceDuration: 30.0 + Double(index * 10),
                feedbackDetailsData: feedbackDetailsData
            )
        }
    }
}
