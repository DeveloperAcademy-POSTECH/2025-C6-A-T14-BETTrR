import XCTest
import GRDB
@testable import Bettr

final class ScriptRepositoryTests: XCTestCase {
    var sut: ScriptRepository!
    var dbQueue: DatabaseQueue!
    
    override func setUp() {
        super.setUp()
        
        dbQueue = try! DatabaseQueue()
        try! setupDatabase(dbQueue)
        sut = ScriptRepository(dbQueue: dbQueue)
    }
    
    override func tearDown() {
        sut = nil
        dbQueue = nil
        super.tearDown()
    }
    
    private func setupDatabase(_ db: DatabaseQueue) throws {
        try db.write { db in
            try db.create(table: "script") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("title", .text).notNull()
                t.column("createdAt", .datetime).notNull()
                t.column("lastViewedAt", .datetime).notNull()
            }
            
            try db.create(table: "sentence") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("scriptId", .integer).notNull()
                    .references("script", onDelete: .cascade)
                t.column("orderIndex", .integer).notNull()
                t.column("englishText", .text).notNull()
                t.column("koreanText", .text).notNull()
            }
            
            try db.create(table: "chunk") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("sentenceId", .integer).notNull()
                    .references("sentence", onDelete: .cascade)
                t.column("orderIndex", .integer).notNull()
                t.column("englishText", .text).notNull()
                t.column("koreanText", .text).notNull()
            }

            try db.create(table: "practice_session") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("scriptId", .integer).notNull().references("script", onDelete: .cascade)
                t.column("recordingPath", .text).notNull()
                t.column("totalPresentationTime", .double).notNull()
                t.column("createdAt", .datetime).notNull()
            }

            try db.create(table: "feedback_summary") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("practiceSessionId", .integer).notNull().references("practice_session", onDelete: .cascade).unique()
                t.column("totalScore", .double).notNull()
                t.column("missingWordCount", .integer).notNull()
                t.column("addedWordCount", .integer).notNull()
                t.column("replacedWordCount", .integer).notNull()
                t.column("analyzedAt", .datetime).notNull()
            }

            try db.create(table: "feedback_detail") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("feedbackSummaryId", .integer).notNull().references("feedback_summary", onDelete: .cascade)
                t.column("errorType", .text).notNull()
                t.column("originalText", .text)
                t.column("spokenText", .text)
                t.column("startTime", .double).notNull()
                t.column("endTime", .double).notNull()
            }
        }
    }
    
    // MARK: - Script Create Tests
    func test_createScript_whenValidScriptDataProvided_thenScriptIsCreatedSuccessfully() throws {
        // Given: 유효한 ScriptData가 존재할 때
        let scriptData = ScriptData(
            title: "Test Script",
            sentences: [
                SentenceData(
                    orderIndex: 0,
                    englishText: "Hello world",
                    koreanText: "안녕 세상",
                    chunks: [
                        ChunkData(orderIndex: 0, englishText: "Hello", koreanText: "안녕"),
                        ChunkData(orderIndex: 1, englishText: "world", koreanText: "세상")
                    ]
                )
            ]
        )
        
        // When: createScript를 호출했을 때
        let createdScript = try sut.createScript(scriptData: scriptData)
        
        // Then: Script가 성공적으로 생성되어야 함
        XCTAssertNotNil(createdScript.id)
        XCTAssertEqual(createdScript.title, "Test Script")
        XCTAssertNotNil(createdScript.createdAt)
        XCTAssertNotNil(createdScript.lastViewedAt)
    }
    
    func test_createScript_whenScriptCreated_thenScriptExistsInDatabase() throws {
        // Given: ScriptData가 존재할 때
        let scriptData = ScriptData(
            title: "Database Test Script",
            sentences: [
                SentenceData(
                    orderIndex: 0,
                    englishText: "A single sentence.",
                    koreanText: "하나의 문장.",
                    chunks: [ChunkData(orderIndex: 0, englishText: "Dummy", koreanText: "더미")]
                )
            ]
        )
        
        // When: Script를 생성했을 때
        let createdScript = try sut.createScript(scriptData: scriptData)
        
        // Then: 데이터베이스에 Script가 존재해야 함
        let fetchedScript = try dbQueue.read { db in
            try Script.fetchOne(db, key: createdScript.id)
        }
        
        XCTAssertNotNil(fetchedScript)
        XCTAssertEqual(fetchedScript?.title, "Database Test Script")
    }
    
    func test_createScript_whenSentencesProvided_thenSentencesAreCreatedWithCorrectOrder() throws {
        // Given: 여러 문장을 포함한 ScriptData가 존재할 때
        let scriptData = ScriptData(
            title: "Multi Sentence Script",
            sentences: [
                SentenceData(
                    orderIndex: 0,
                    englishText: "First sentence",
                    koreanText: "첫 번째 문장",
                    chunks: [ChunkData(orderIndex: 0, englishText: "Dummy1", koreanText: "더미1")]
                ),
                SentenceData(
                    orderIndex: 1,
                    englishText: "Second sentence",
                    koreanText: "두 번째 문장",
                    chunks: [ChunkData(orderIndex: 0, englishText: "Dummy2", koreanText: "더미2")]
                )
            ]
        )
        
        // When: Script를 생성했을 때
        let createdScript = try sut.createScript(scriptData: scriptData)
        
        // Then: Sentence들이 올바른 순서로 생성되어야 함
        let sentences = try dbQueue.read { db in
            try Sentence
                .filter(Column("scriptId") == createdScript.id!)
                .order(Column("orderIndex"))
                .fetchAll(db)
        }
        
        XCTAssertEqual(sentences.count, 2)
        XCTAssertEqual(sentences[0].orderIndex, 0)
        XCTAssertEqual(sentences[0].englishText, "First sentence")
        XCTAssertEqual(sentences[1].orderIndex, 1)
        XCTAssertEqual(sentences[1].englishText, "Second sentence")
    }
    
    func test_createScript_whenChunksProvided_thenChunksAreCreatedWithCorrectOrder() throws {
        // Given: Chunk를 포함한 Sentence가 존재할 때
        let scriptData = ScriptData(
            title: "Chunked Script",
            sentences: [
                SentenceData(
                    orderIndex: 0,
                    englishText: "Hello world today",
                    koreanText: "안녕 세상 오늘",
                    chunks: [
                        ChunkData(orderIndex: 0, englishText: "Hello", koreanText: "안녕"),
                        ChunkData(orderIndex: 1, englishText: "world", koreanText: "세상"),
                        ChunkData(orderIndex: 2, englishText: "today", koreanText: "오늘")
                    ]
                )
            ]
        )
        
        // When: Script를 생성했을 때
        let createdScript = try sut.createScript(scriptData: scriptData)
        
        // Then: Chunk들이 올바른 순서로 생성되어야 함
        let sentence = try dbQueue.read { db in
            try Sentence
                .filter(Column("scriptId") == createdScript.id!)
                .fetchOne(db)
        }
        
        let chunks = try dbQueue.read { db in
            try Chunk
                .filter(Column("sentenceId") == sentence!.id!)
                .order(Column("orderIndex"))
                .fetchAll(db)
        }
        
        XCTAssertEqual(chunks.count, 3)
        XCTAssertEqual(chunks[0].orderIndex, 0)
        XCTAssertEqual(chunks[0].englishText, "Hello")
        XCTAssertEqual(chunks[1].orderIndex, 1)
        XCTAssertEqual(chunks[1].englishText, "world")
        XCTAssertEqual(chunks[2].orderIndex, 2)
        XCTAssertEqual(chunks[2].englishText, "today")
    }
    
    func test_createScript_whenComplexDataProvided_thenAllRelationshipsAreCreatedCorrectly() throws {
        // Given: 복잡한 ScriptData가 존재할 때
        let scriptData = ScriptData(
            title: "Complex Script",
            sentences: [
                SentenceData(
                    orderIndex: 0,
                    englishText: "First sentence",
                    koreanText: "첫 번째 문장",
                    chunks: [
                        ChunkData(orderIndex: 0, englishText: "First", koreanText: "첫 번째"),
                        ChunkData(orderIndex: 1, englishText: "sentence", koreanText: "문장")
                    ]
                ),
                SentenceData(
                    orderIndex: 1,
                    englishText: "Second sentence",
                    koreanText: "두 번째 문장",
                    chunks: [
                        ChunkData(orderIndex: 0, englishText: "Second", koreanText: "두 번째"),
                        ChunkData(orderIndex: 1, englishText: "sentence", koreanText: "문장")
                    ]
                )
            ]
        )
        
        // When: Script를 생성했을 때
        let createdScript = try sut.createScript(scriptData: scriptData)
        
        // Then: 모든 관계가 올바르게 생성되어야 함
        let scriptCount = try dbQueue.read { db in
            try Script.fetchCount(db)
        }
        let sentenceCount = try dbQueue.read { db in
            try Sentence.filter(Column("scriptId") == createdScript.id!).fetchCount(db)
        }
        let chunkCount = try dbQueue.read { db in
            try Chunk.fetchCount(db)
        }
        
        XCTAssertEqual(scriptCount, 1)
        XCTAssertEqual(sentenceCount, 2)
        XCTAssertEqual(chunkCount, 4)
    }
    
    func test_createScript_whenEmptySentences_thenOnlyScriptIsCreated() throws {
        // Given: 문장이 없는 ScriptData가 존재할 때
        let scriptData = ScriptData(
            title: "Empty Script",
            sentences: []
        )
        
        // When-Then: Script 생성 시 오류가 발생해야 함
        XCTAssertThrowsError(try sut.createScript(scriptData: scriptData)) {
            error in
            XCTAssertEqual((error as? ScriptRepositoryError)?.errorDescription, ScriptRepositoryError.validationError(message: "A Script must contain at least one sentence.").errorDescription)
        }
    }
    
    func test_createScript_whenEmptyChunks_thenThrowsError() throws {
        // Given: Chunk가 없는 Sentence가 포함된 ScriptData가 존재할 때
        let scriptData = ScriptData(
            title: "Script with Empty Chunks",
            sentences: [
                SentenceData(
                    orderIndex: 0,
                    englishText: "Sentence with no chunks.",
                    koreanText: "청크 없는 문장.",
                    chunks: []
                )
            ]
        )
        
        // When-Then: Script 생성 시 검증 오류가 발생해야 함
        XCTAssertThrowsError(try sut.createScript(scriptData: scriptData)) {
            error in
            XCTAssertEqual((error as? ScriptRepositoryError)?.errorDescription, ScriptRepositoryError.validationError(message: "A Sentence must contain at least one chunk.").errorDescription)
        }
    }
    
    // MARK: - Read Tests
    
    func test_fetchScript_whenScriptExists_thenReturnsScript() throws {
        // Given: Script가 존재할 때
        let scriptData = ScriptData(
            title: "Fetchable Script",
            sentences: [
                SentenceData(orderIndex: 0, englishText: "A sentence.", koreanText: "문장.", chunks: [ChunkData(orderIndex: 0, englishText: "Dummy", koreanText: "더미")])
            ]
        )
        let createdScript = try sut.createScript(scriptData: scriptData)
        
        // When: 해당 Script ID로 조회했을 때
        let fetchedScript = try sut.fetchScript(id: createdScript.id!)
        
        // Then: 올바른 Script가 반환되어야 함
        XCTAssertNotNil(fetchedScript)
        XCTAssertEqual(fetchedScript?.title, "Fetchable Script")
        XCTAssertEqual(fetchedScript?.id, createdScript.id)
    }
    
    func test_fetchScript_whenScriptDoesNotExist_thenReturnsNil() throws {
        // Given: 존재하지 않는 Script ID가 있을 때
        let nonExistentId: Int64 = 9999
        
        // When: 해당 ID로 Script를 조회했을 때
        let fetchedScript = try sut.fetchScript(id: nonExistentId)
        
        // Then: nil이 반환되어야 함
        XCTAssertNil(fetchedScript)
    }
    
    func test_fetchAllScripts_whenScriptsExist_thenReturnsAllScripts() throws {
        // Given: 여러 Script가 존재할 때
        let scriptData1 = ScriptData(
            title: "Script One",
            sentences: [
                SentenceData(orderIndex: 0, englishText: "S1.", koreanText: "S1.", chunks: [ChunkData(orderIndex: 0, englishText: "Dummy1", koreanText: "더미1")])
            ]
        )
        let scriptData2 = ScriptData(
            title: "Script Two",
            sentences: [
                SentenceData(orderIndex: 0, englishText: "S2.", koreanText: "S2.", chunks: [ChunkData(orderIndex: 0, englishText: "Dummy2", koreanText: "더미2")])
            ]
        )
        _ = try sut.createScript(scriptData: scriptData1)
        _ = try sut.createScript(scriptData: scriptData2)
        
        // When: 모든 Script를 조회했을 때
        let allScripts = try sut.fetchAllScripts()
        
        // Then: 모든 Script가 반환되어야 함
        XCTAssertEqual(allScripts.count, 2)
        XCTAssertTrue(allScripts.contains(where: { $0.title == "Script One" }))
        XCTAssertTrue(allScripts.contains(where: { $0.title == "Script Two" }))
    }
    
    func test_fetchAllScripts_whenNoScriptsExist_thenReturnsEmptyArray() throws {
        // Given: 데이터베이스에 Script가 없을 때
        
        // When: 모든 Script를 조회했을 때
        let allScripts = try sut.fetchAllScripts()
        
        // Then: 빈 배열이 반환되어야 함
        XCTAssertTrue(allScripts.isEmpty)
    }

    // MARK: - Script Update Tests

    func test_updateLastViewedAt_whenScriptExists_thenUpdatesTimestamp() throws {
        // Given: Script가 존재할 때
        let scriptData = ScriptData(
            title: "Script to Update",
            sentences: [
                SentenceData(orderIndex: 0, englishText: "Sentence.", koreanText: "문장.", chunks: [ChunkData(orderIndex: 0, englishText: "Chunk", koreanText: "청크")])
            ]
        )
        let createdScript = try sut.createScript(scriptData: scriptData)
        let initialLastViewedAt = createdScript.lastViewedAt

        // When: lastViewedAt을 갱신했을 때
        Thread.sleep(forTimeInterval: 0.01)
        try sut.updateLastViewedAt(forScriptId: createdScript.id!)

        // Then: 타임스탬프가 업데이트되어야 함
        let updatedScript = try sut.fetchScript(id: createdScript.id!)
        XCTAssertNotNil(updatedScript)
        XCTAssertNotEqual(updatedScript?.lastViewedAt, initialLastViewedAt)
        XCTAssertTrue(updatedScript!.lastViewedAt > initialLastViewedAt)
    }

    func test_updateLastViewedAt_whenScriptDoesNotExist_thenThrowsError() throws {
        // Given: 존재하지 않는 Script ID가 있을 때
        let nonExistentId: Int64 = 9999

        // When-Then: 업데이트 시 notFound 오류가 발생해야 함
        XCTAssertThrowsError(try sut.updateLastViewedAt(forScriptId: nonExistentId)) {
            error in
            XCTAssertEqual((error as? ScriptRepositoryError)?.errorDescription, ScriptRepositoryError.notFound(message: "Script with ID \(nonExistentId) not found.").errorDescription)
        }
    }

    // MARK: - PracticeSession Create Tests

    func test_createPracticeSession_whenValidDataProvided_thenCreatesSuccessfully() throws {
        // Given: Script가 존재하고 유효한 PracticeSession 데이터가 있을 때
        let scriptData = ScriptData(
            title: "Test Script for Practice Session",
            sentences: [
                SentenceData(orderIndex: 0, englishText: "Hello.", koreanText: "안녕.", chunks: [ChunkData(orderIndex: 0, englishText: "Hello", koreanText: "안녕")])
            ]
        )
        let createdScript = try sut.createScript(scriptData: scriptData)
        
        let recordingPath = "path/to/recording.m4a"
        let totalPresentationTime: Double = 120.5
        
        // When: PracticeSession을 생성했을 때
        let createdSession = try sut.createPracticeSession(
            scriptId: createdScript.id!,
            recordingPath: recordingPath,
            totalPresentationTime: totalPresentationTime
        )
        
        // Then: PracticeSession이 성공적으로 생성되어야 함
        XCTAssertNotNil(createdSession.id)
        XCTAssertEqual(createdSession.scriptId, createdScript.id)
        XCTAssertEqual(createdSession.recordingPath, recordingPath)
        XCTAssertEqual(createdSession.totalPresentationTime, totalPresentationTime)
        XCTAssertNotNil(createdSession.createdAt)
    }
    
    func test_createPracticeSession_whenScriptDoesNotExist_thenThrowsError() throws {
        // Given: 존재하지 않는 Script ID가 있을 때
        let nonExistentScriptId: Int64 = 9999
        let recordingPath = "path/to/recording.m4a"
        let totalPresentationTime: Double = 120.5
        
        // When-Then: PracticeSession 생성 시 notFound 오류가 발생해야 함
        XCTAssertThrowsError(try sut.createPracticeSession(
            scriptId: nonExistentScriptId,
            recordingPath: recordingPath,
            totalPresentationTime: totalPresentationTime
        )) {
            error in
            XCTAssertEqual((error as? ScriptRepositoryError)?.errorDescription, ScriptRepositoryError.notFound(message: "Script with ID \(nonExistentScriptId) not found.").errorDescription)
        }
    }
    
    func test_createPracticeSession_whenPracticeSessionCreated_thenExistsInDatabase() throws {
        // Given: 스크립트가 존재하고 유효한 연습 세션 데이터가 제공된 경우
        let scriptData = ScriptData(
            title: "Test Script for DB Check",
            sentences: [
                SentenceData(orderIndex: 0, englishText: "Hello.", koreanText: "안녕.", chunks: [ChunkData(orderIndex: 0, englishText: "Hello", koreanText: "안녕")])
            ]
        )
        let createdScript = try sut.createScript(scriptData: scriptData)
        
        let recordingPath = "path/to/recording.m4a"
        let totalPresentationTime: Double = 120.5
        
        // When: 연습 세션을 생성할 때
        let createdSession = try sut.createPracticeSession(
            scriptId: createdScript.id!,
            recordingPath: recordingPath,
            totalPresentationTime: totalPresentationTime
        )
        
        // Then: 생성된 연습 세션이 데이터베이스에 존재해야 함
        let fetchedSession = try dbQueue.read { db in
            try PracticeSession.fetchOne(db, key: createdSession.id)
        }
        XCTAssertNotNil(fetchedSession)
        XCTAssertEqual(fetchedSession?.id, createdSession.id)
        XCTAssertEqual(fetchedSession?.scriptId, createdScript.id)
    }

    // MARK: - FeedbackSummary Create Tests

    func test_createFeedbackSummary_whenValidDataProvided_thenCreatesSuccessfully() throws {
        // Given: Script와 PracticeSession이 존재하고 유효한 FeedbackSummary 데이터가 있을 때
        let scriptData = ScriptData(
            title: "Test Script for Feedback Summary",
            sentences: [
                SentenceData(orderIndex: 0, englishText: "Hello.", koreanText: "안녕.", chunks: [ChunkData(orderIndex: 0, englishText: "Hello", koreanText: "안녕")])
            ]
        )
        let createdScript = try sut.createScript(scriptData: scriptData)

        let createdSession = try sut.createPracticeSession(
            scriptId: createdScript.id!,
            recordingPath: "path/to/recording.m4a",
            totalPresentationTime: 120.5
        )

        let feedbackDetailsData: [(errorType: FeedbackErrorType, originalText: String?, spokenText: String?, startTime: Double, endTime: Double)] = [
            (errorType: .missingWord, originalText: "original1", spokenText: nil, startTime: 1.0, endTime: 2.0),
            (errorType: .addedWord, originalText: nil, spokenText: "spoken1", startTime: 3.0, endTime: 4.0),
            (errorType: .replacedWord, originalText: "original2", spokenText: "spoken2", startTime: 5.0, endTime: 6.0)
        ]

        // When: FeedbackSummary를 생성하면
        let createdSummary = try sut.createFeedbackSummary(
            practiceSessionId: createdSession.id!,
            totalScore: 95.5,
            missingWordCount: 1,
            addedWordCount: 1,
            replacedWordCount: 1,
            feedbackDetailsData: feedbackDetailsData
        )

        // Then: 성공적으로 생성되어야 함
        XCTAssertNotNil(createdSummary.id)
        XCTAssertEqual(createdSummary.practiceSessionId, createdSession.id)
        XCTAssertEqual(createdSummary.totalScore, 95.5)
        XCTAssertEqual(createdSummary.missingWordCount, 1)
        XCTAssertEqual(createdSummary.addedWordCount, 1)
        XCTAssertEqual(createdSummary.replacedWordCount, 1)
        XCTAssertNotNil(createdSummary.analyzedAt)

        // 그리고 관련 FeedbackDetail도 생성되어야 함
        let fetchedDetails = try dbQueue.read { db in
            try FeedbackDetail.filter(Column("feedbackSummaryId") == createdSummary.id!).fetchAll(db)
        }
        XCTAssertEqual(fetchedDetails.count, 3)
        XCTAssertTrue(fetchedDetails.contains(where: { $0.errorType == .missingWord && $0.originalText == "original1" }))
        XCTAssertTrue(fetchedDetails.contains(where: { $0.errorType == .addedWord && $0.spokenText == "spoken1" }))
        XCTAssertTrue(fetchedDetails.contains(where: { $0.errorType == .replacedWord && $0.originalText == "original2" && $0.spokenText == "spoken2" }))
    }

    func test_createFeedbackSummary_whenPracticeSessionDoesNotExist_thenThrowsError() throws {
        // Given: 존재하지 않는 PracticeSession ID가 있을 때
        let nonExistentPracticeSessionId: Int64 = 9999

        let feedbackDetailsData: [(errorType: FeedbackErrorType, originalText: String?, spokenText: String?, startTime: Double, endTime: Double)] = [
            (errorType: .missingWord, originalText: "original1", spokenText: nil, startTime: 1.0, endTime: 2.0)
        ]

        // When-Then: FeedbackSummary 생성 시 notFound 오류가 발생해야 함
        XCTAssertThrowsError(try sut.createFeedbackSummary(
            practiceSessionId: nonExistentPracticeSessionId,
            totalScore: 90.0,
            missingWordCount: 0,
            addedWordCount: 0,
            replacedWordCount: 0,
            feedbackDetailsData: feedbackDetailsData
        )) {
            error in
            XCTAssertEqual((error as? ScriptRepositoryError)?.errorDescription, ScriptRepositoryError.notFound(message: "PracticeSession with ID \(nonExistentPracticeSessionId) not found.").errorDescription)
        }
    }

    func test_createFeedbackSummary_whenFeedbackSummaryAlreadyExists_thenThrowsError() throws {
        // Given: 이미 FeedbackSummary가 존재하는 PracticeSession이 있을 때
        let scriptData = ScriptData(
            title: "Script for existing summary",
            sentences: [
                SentenceData(orderIndex: 0, englishText: "Test.", koreanText: "테스트.", chunks: [ChunkData(orderIndex: 0, englishText: "Test", koreanText: "테스트")])
            ]
        )
        let createdScript = try sut.createScript(scriptData: scriptData)

        let createdSession = try sut.createPracticeSession(
            scriptId: createdScript.id!,
            recordingPath: "path/to/recording.m4a",
            totalPresentationTime: 60.0
        )

        let feedbackDetailsData: [(errorType: FeedbackErrorType, originalText: String?, spokenText: String?, startTime: Double, endTime: Double)] = [
            (errorType: .missingWord, originalText: "original", spokenText: nil, startTime: 1.0, endTime: 2.0)
        ]

        // 첫 번째 FeedbackSummary 생성
        _ = try sut.createFeedbackSummary(
            practiceSessionId: createdSession.id!,
            totalScore: 80.0,
            missingWordCount: 1,
            addedWordCount: 0,
            replacedWordCount: 0,
            feedbackDetailsData: feedbackDetailsData
        )

        // When-Then: 동일한 PracticeSession ID로 두 번째 FeedbackSummary 생성 시 validationError 오류가 발생해야 함
        XCTAssertThrowsError(try sut.createFeedbackSummary(
            practiceSessionId: createdSession.id!,
            totalScore: 70.0,
            missingWordCount: 0,
            addedWordCount: 1,
            replacedWordCount: 0,
            feedbackDetailsData: feedbackDetailsData
        )) {
            error in
            XCTAssertEqual((error as? ScriptRepositoryError)?.errorDescription, ScriptRepositoryError.validationError(message: "FeedbackSummary already exists for PracticeSession ID \(createdSession.id!).").errorDescription)
        }
    }

    func test_createFeedbackSummary_whenFeedbackDetailsDataIsEmpty_thenThrowsError() throws {
        // Given: Script와 PracticeSession이 존재하지만 feedbackDetailsData가 비어있을 때
        let scriptData = ScriptData(
            title: "Script for empty details",
            sentences: [
                SentenceData(orderIndex: 0, englishText: "Empty.", koreanText: "비어있음.", chunks: [ChunkData(orderIndex: 0, englishText: "Empty", koreanText: "비어있음")])
            ]
        )
        let createdScript = try sut.createScript(scriptData: scriptData)

        let createdSession = try sut.createPracticeSession(
            scriptId: createdScript.id!,
            recordingPath: "path/to/recording.m4a",
            totalPresentationTime: 30.0
        )

        let emptyFeedbackDetailsData: [(errorType: FeedbackErrorType, originalText: String?, spokenText: String?, startTime: Double, endTime: Double)] = []

        // When-Then: FeedbackSummary 생성 시 validationError 오류가 발생해야 함
        XCTAssertThrowsError(try sut.createFeedbackSummary(
            practiceSessionId: createdSession.id!,
            totalScore: 100.0,
            missingWordCount: 0,
            addedWordCount: 0,
            replacedWordCount: 0,
            feedbackDetailsData: emptyFeedbackDetailsData
        )) {
            error in
            XCTAssertEqual((error as? ScriptRepositoryError)?.errorDescription, ScriptRepositoryError.validationError(message: "FeedbackSummary must contain at least one FeedbackDetail.").errorDescription)
        }
    }

    // MARK: - Script Delete Tests

    func test_deleteScript_whenScriptExists_thenDeletesScriptAndAllRelatedEntities() throws {
        // Given: Script와 연관된 모든 엔티티들이 존재할 때
        let scriptData = ScriptData(
            title: "Script to be deleted",
            sentences: [
                SentenceData(
                    orderIndex: 0,
                    englishText: "Sentence 1",
                    koreanText: "문장 1",
                    chunks: [
                        ChunkData(orderIndex: 0, englishText: "Chunk 1", koreanText: "청크 1")
                    ]
                )
            ]
        )
        let createdScript = try sut.createScript(scriptData: scriptData)
        let scriptId = createdScript.id!

        let createdSession = try sut.createPracticeSession(
            scriptId: scriptId,
            recordingPath: "path/to/recording.m4a",
            totalPresentationTime: 100.0
        )
        let sessionId = createdSession.id!

        let feedbackDetailsData: [(errorType: FeedbackErrorType, originalText: String?, spokenText: String?, startTime: Double, endTime: Double)] = [
            (errorType: .missingWord, originalText: "original", spokenText: nil, startTime: 1.0, endTime: 2.0)
        ]
        let createdSummary = try sut.createFeedbackSummary(
            practiceSessionId: sessionId,
            totalScore: 90.0,
            missingWordCount: 1,
            addedWordCount: 0,
            replacedWordCount: 0,
            feedbackDetailsData: feedbackDetailsData
        )
        let summaryId = createdSummary.id!

        // When: Script를 삭제했을 때
        try sut.deleteScript(id: scriptId)

        // Then: Script와 모든 연관 엔티티들이 삭제되어야 함
        let fetchedScript = try sut.fetchScript(id: scriptId)
        XCTAssertNil(fetchedScript)

        let sentenceCount = try dbQueue.read { db in
            try Sentence.filter(Column("scriptId") == scriptId).fetchCount(db)
        }
        XCTAssertEqual(sentenceCount, 0)

        let chunkCount = try dbQueue.read { db in
            try Chunk.fetchCount(db)
        }
        XCTAssertEqual(chunkCount, 0)

        let practiceSessionCount = try dbQueue.read { db in
            try PracticeSession.filter(Column("scriptId") == scriptId).fetchCount(db)
        }
        XCTAssertEqual(practiceSessionCount, 0)

        let feedbackSummaryCount = try dbQueue.read { db in
            try FeedbackSummary.filter(Column("practiceSessionId") == sessionId).fetchCount(db)
        }
        XCTAssertEqual(feedbackSummaryCount, 0)

        let feedbackDetailCount = try dbQueue.read { db in
            try FeedbackDetail.filter(Column("feedbackSummaryId") == summaryId).fetchCount(db)
        }
        XCTAssertEqual(feedbackDetailCount, 0)
    }

    func test_deleteScript_whenScriptDoesNotExist_thenThrowsError() throws {
        // Given: 존재하지 않는 Script ID가 있을 때
        let nonExistentId: Int64 = 9999

        // When-Then: 삭제 시 notFound 오류가 발생해야 함
        XCTAssertThrowsError(try sut.deleteScript(id: nonExistentId)) {
            error in
            XCTAssertEqual((error as? ScriptRepositoryError)?.errorDescription, ScriptRepositoryError.notFound(message: "Script with ID \(nonExistentId) not found.").errorDescription)
        }
    }

    // MARK: - PracticeSession Read Tests

    func test_fetchPracticeSessions_whenSessionsExist_thenReturnsAllSessions() throws {
        // Given: Script와 여러 PracticeSession이 존재할 때
        let scriptData = ScriptData(
            title: "Script with multiple sessions",
            sentences: [
                SentenceData(orderIndex: 0, englishText: "Hello.", koreanText: "안녕.", chunks: [ChunkData(orderIndex: 0, englishText: "Hello", koreanText: "안녕")])
            ]
        )
        let createdScript = try sut.createScript(scriptData: scriptData)
        let scriptId = createdScript.id!

        _ = try sut.createPracticeSession(
            scriptId: scriptId,
            recordingPath: "path/to/session1.m4a",
            totalPresentationTime: 60.0
        )
        _ = try sut.createPracticeSession(
            scriptId: scriptId,
            recordingPath: "path/to/session2.m4a",
            totalPresentationTime: 70.0
        )

        // When: 해당 Script ID로 PracticeSession을 조회했을 때
        let fetchedSessions = try sut.fetchPracticeSessions(forScriptId: scriptId)

        // Then: 모든 PracticeSession이 반환되어야 함
        XCTAssertEqual(fetchedSessions.count, 2)
        XCTAssertTrue(fetchedSessions.contains(where: { $0.recordingPath == "path/to/session1.m4a" }))
        XCTAssertTrue(fetchedSessions.contains(where: { $0.recordingPath == "path/to/session2.m4a" }))
    }

    func test_fetchPracticeSessions_whenNoSessionsExist_thenReturnsEmptyArray() throws {
        // Given: Script는 존재하지만 PracticeSession이 없을 때
        let scriptData = ScriptData(
            title: "Script with no sessions",
            sentences: [
                SentenceData(orderIndex: 0, englishText: "Hello.", koreanText: "안녕.", chunks: [ChunkData(orderIndex: 0, englishText: "Hello", koreanText: "안녕")])
            ]
        )
        let createdScript = try sut.createScript(scriptData: scriptData)
        let scriptId = createdScript.id!

        // When: 해당 Script ID로 PracticeSession을 조회했을 때
        let fetchedSessions = try sut.fetchPracticeSessions(forScriptId: scriptId)

        // Then: 빈 배열이 반환되어야 함
        XCTAssertTrue(fetchedSessions.isEmpty)
    }

    // MARK: - Feedback Read Tests

    func test_fetchFeedbackSummary_whenSummaryExists_thenReturnsSummary() throws {
        // Given: FeedbackSummary가 존재하는 PracticeSession이 있을 때
        let scriptData = ScriptData(
            title: "Script for summary fetch",
            sentences: [
                SentenceData(orderIndex: 0, englishText: "Test.", koreanText: "테스트.", chunks: [ChunkData(orderIndex: 0, englishText: "Test", koreanText: "테스트")])
            ]
        )
        let createdScript = try sut.createScript(scriptData: scriptData)

        let createdSession = try sut.createPracticeSession(
            scriptId: createdScript.id!,
            recordingPath: "path/to/recording.m4a",
            totalPresentationTime: 60.0
        )
        let sessionId = createdSession.id!

        let feedbackDetailsData: [(errorType: FeedbackErrorType, originalText: String?, spokenText: String?, startTime: Double, endTime: Double)] = [
            (errorType: .missingWord, originalText: "original", spokenText: nil, startTime: 1.0, endTime: 2.0)
        ]
        let createdSummary = try sut.createFeedbackSummary(
            practiceSessionId: sessionId,
            totalScore: 80.0,
            missingWordCount: 1,
            addedWordCount: 0,
            replacedWordCount: 0,
            feedbackDetailsData: feedbackDetailsData
        )

        // When: 해당 PracticeSession ID로 FeedbackSummary를 조회했을 때
        let fetchedSummary = try sut.fetchFeedbackSummary(forPracticeSessionId: sessionId)

        // Then: 올바른 FeedbackSummary가 반환되어야 함
        XCTAssertNotNil(fetchedSummary)
        XCTAssertEqual(fetchedSummary?.id, createdSummary.id)
        XCTAssertEqual(fetchedSummary?.totalScore, 80.0)
    }

    func test_fetchFeedbackSummary_whenSummaryDoesNotExist_thenReturnsNil() throws {
        // Given: FeedbackSummary가 존재하지 않는 PracticeSession ID가 있을 때
        let scriptData = ScriptData(
            title: "Script for no summary",
            sentences: [
                SentenceData(orderIndex: 0, englishText: "Test.", koreanText: "테스트.", chunks: [ChunkData(orderIndex: 0, englishText: "Test", koreanText: "테스트")])
            ]
        )
        let createdScript = try sut.createScript(scriptData: scriptData)

        let createdSession = try sut.createPracticeSession(
            scriptId: createdScript.id!,
            recordingPath: "path/to/recording.m4a",
            totalPresentationTime: 60.0
        )
        let sessionId = createdSession.id!

        // When: 해당 PracticeSession ID로 FeedbackSummary를 조회했을 때
        let fetchedSummary = try sut.fetchFeedbackSummary(forPracticeSessionId: sessionId)

        // Then: nil이 반환되어야 함
        XCTAssertNil(fetchedSummary)
    }

    func test_fetchFeedbackDetails_whenDetailsExist_thenReturnsAllDetails() throws {
        // Given: FeedbackDetail이 존재하는 FeedbackSummary가 있을 때
        let scriptData = ScriptData(
            title: "Script for details fetch",
            sentences: [
                SentenceData(orderIndex: 0, englishText: "Test.", koreanText: "테스트.", chunks: [ChunkData(orderIndex: 0, englishText: "Test", koreanText: "테스트")])
            ]
        )
        let createdScript = try sut.createScript(scriptData: scriptData)

        let createdSession = try sut.createPracticeSession(
            scriptId: createdScript.id!,
            recordingPath: "path/to/recording.m4a",
            totalPresentationTime: 60.0
        )
        let sessionId = createdSession.id!

        let feedbackDetailsData: [(errorType: FeedbackErrorType, originalText: String?, spokenText: String?, startTime: Double, endTime: Double)] = [
            (errorType: .missingWord, originalText: "original1", spokenText: nil, startTime: 1.0, endTime: 2.0),
            (errorType: .addedWord, originalText: nil, spokenText: "spoken1", startTime: 3.0, endTime: 4.0)
        ]
        let createdSummary = try sut.createFeedbackSummary(
            practiceSessionId: sessionId,
            totalScore: 80.0,
            missingWordCount: 1,
            addedWordCount: 1,
            replacedWordCount: 0,
            feedbackDetailsData: feedbackDetailsData
        )
        let summaryId = createdSummary.id!

        // When: 해당 FeedbackSummary ID로 FeedbackDetail을 조회했을 때
        let fetchedDetails = try sut.fetchFeedbackDetails(forFeedbackSummaryId: summaryId)

        // Then: 모든 FeedbackDetail이 반환되어야 함
        XCTAssertEqual(fetchedDetails.count, 2)
        XCTAssertTrue(fetchedDetails.contains(where: { $0.errorType == .missingWord && $0.originalText == "original1" }))
        XCTAssertTrue(fetchedDetails.contains(where: { $0.errorType == .addedWord && $0.spokenText == "spoken1" }))
    }

    func test_fetchFeedbackDetails_whenNoDetailsExist_thenReturnsEmptyArray() throws {
        // Given: 존재하지 않는 FeedbackSummary ID가 있을 때
        let nonExistentSummaryId: Int64 = 9999

        // When: 해당 FeedbackSummary ID로 FeedbackDetail을 조회했을 때
        let fetchedDetails = try sut.fetchFeedbackDetails(forFeedbackSummaryId: nonExistentSummaryId)

        // Then: 빈 배열이 반환되어야 함
        XCTAssertTrue(fetchedDetails.isEmpty)
    }
}
