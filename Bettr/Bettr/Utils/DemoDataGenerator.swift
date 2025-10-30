
import Foundation
import GRDB

struct DemoDataGenerator {
    static func generate(into database: AppDatabase) throws {
        let scriptRepository = ScriptRepository()
        let scriptManagementService = ScriptManagementService(dbQueue: database.dbQueue, scriptRepository: scriptRepository)
        let practiceSessionService = PracticeSessionService(dbQueue: database.dbQueue, scriptRepository: scriptRepository)

        // Check if demo data already exists to prevent duplicates
        let existingScripts = try scriptManagementService.fetchAllScripts()
        if !existingScripts.isEmpty {
            print("ℹ️ Demo data already exists. Skipping creation.")
            return
        }

        let demoScriptData: [ScriptData] = [
            ScriptData(
                title: "Sample Script 1",
                sentences: [
                    SentenceData(
                        orderIndex: 0,
                        englishText: "Hello world",
                        koreanText: "안녕 세상",
                        chunks: [
                            ChunkData(orderIndex: 0, englishText: "Hello", koreanText: "안녕")
                        ]
                    )
                ]
            ),
            ScriptData(
                title: "Another Script Example",
                sentences: [
                    SentenceData(
                        orderIndex: 0,
                        englishText: "This is another example for the preview.",
                        koreanText: "이것은 미리보기를 위한 또 다른 예시입니다.",
                        chunks: [
                            ChunkData(orderIndex: 0, englishText: "This is another example", koreanText: "이것은 또 다른 예시입니다"),
                            ChunkData(orderIndex: 1, englishText: "for the preview.", koreanText: "미리보기를 위한.")
                        ]
                    )
                ]
            ),
            ScriptData(
                title: "Third Script for Testing",
                sentences: [
                    SentenceData(
                        orderIndex: 0,
                        englishText: "A third script to ensure proper display.",
                        koreanText: "적절한 표시를 위한 세 번째 스크립트입니다.",
                        chunks: [
                            ChunkData(orderIndex: 0, englishText: "A third script", koreanText: "세 번째 스크립트"),
                            ChunkData(orderIndex: 1, englishText: "to ensure proper display.", koreanText: "적절한 표시를 보장하기 위한.")
                        ]
                    )
                ]
            )
        ]
        
        for (index, scriptData) in demoScriptData.enumerated() {
            let script = try scriptManagementService.createScript(scriptData: scriptData)
            guard let scriptId = script.id else { continue }

            let practiceSession = try practiceSessionService.createPracticeSession(
                scriptId: scriptId,
                recordingPath: "/path/to/preview_recording_\(scriptId).m4a",
                totalPresentationTime: 30.0 + Double(index * 10),
            )

            guard let practiceSessionId = practiceSession.id else { continue }

            let feedbackDetailsData: [(errorType: FeedbackErrorType, originalText: String?, spokenText: String?, startTime: Double, endTime: Double)] = [
                (errorType: .missingWord, originalText: "preview", spokenText: nil, startTime: 1.0, endTime: 1.5),
                (errorType: .addedWord, originalText: nil, spokenText: "extra", startTime: 2.0, endTime: 2.5)
            ]

            _ = try practiceSessionService.createFeedbackSummary(
                practiceSessionId: practiceSessionId,
                totalScore: 60.0 + Double(index * 10),
                missingWordCount: 1,
                addedWordCount: 1,
                replacedWordCount: 0,
                feedbackDetailsData: feedbackDetailsData
            )
        }
    }
}
