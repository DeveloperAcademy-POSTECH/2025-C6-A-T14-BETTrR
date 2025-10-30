import XCTest
import GRDB
@testable import Bettr

final class PracticeSessionServiceTests: XCTestCase {
    var sut: PracticeSessionService!
    var scriptRepository: ScriptRepository!
    var scriptManagementService: ScriptManagementService!
    var dbQueue: DatabaseQueue!
    
    override func setUp() {
        super.setUp()
        
        dbQueue = try! DatabaseQueue()
        try! setupDatabase(dbQueue)
        scriptRepository = ScriptRepository()
        scriptManagementService = ScriptManagementService(dbQueue: dbQueue, scriptRepository: scriptRepository)
        sut = PracticeSessionService(dbQueue: dbQueue, scriptRepository: scriptRepository)
    }
    
    override func tearDown() {
        sut = nil
        scriptManagementService = nil
        scriptRepository = nil
        dbQueue = nil
        super.tearDown()
    }
    
    // MARK: - Helper Methods
    
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
    
    private func createTestScript() throws -> Script {
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
        return try scriptManagementService.createScript(scriptData: scriptData)
    }
    
    // MARK: - PracticeSession Create Tests
    
    func test_createPracticeSession_whenValidDataProvided_thenCreatesSuccessfully() throws {
        // Given: Script가 존재하고 유효한 PracticeSession 데이터가 있을 때
        let createdScript = try createTestScript()
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
        )) { error in
            XCTAssertEqual(
                (error as? ScriptRepositoryError)?.errorDescription,
                ScriptRepositoryError.notFound(message: "Script with ID \(nonExistentScriptId) not found.").errorDescription
            )
        }
    }
    
    func test_createPracticeSession_whenPracticeSessionCreated_thenExistsInDatabase() throws {
        // Given: Script가 존재하고 유효한 연습 세션 데이터가 제공된 경우
        let createdScript = try createTestScript()
        let recordingPath = "path/to/recording.m4a"
        let totalPresentationTime: Double = 120.5
        
        // When: 연습 세션을 생성했을 때
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
    
    // MARK: - PracticeSession Read Tests

    func test_fetchPracticeSession_whenSessionExists_thenReturnsSession() throws {
        // Given: PracticeSession이 존재할 때
        let createdScript = try createTestScript()
        let createdSession = try sut.createPracticeSession(
            scriptId: createdScript.id!,
            recordingPath: "path/to/session.m4a",
            totalPresentationTime: 100.0
        )
        let sessionId = createdSession.id!

        // When: 해당 ID로 PracticeSession을 조회했을 때
        let fetchedSession = try sut.fetchPracticeSession(id: sessionId)

        // Then: 올바른 PracticeSession이 반환되어야 함
        XCTAssertNotNil(fetchedSession)
        XCTAssertEqual(fetchedSession?.id, sessionId)
        XCTAssertEqual(fetchedSession?.recordingPath, "path/to/session.m4a")
    }

    func test_fetchPracticeSession_whenSessionDoesNotExist_thenReturnsNil() throws {
        // Given: 존재하지 않는 PracticeSession ID가 있을 때
        let nonExistentSessionId: Int64 = 9999

        // When: 해당 ID로 PracticeSession을 조회했을 때
        let fetchedSession = try sut.fetchPracticeSession(id: nonExistentSessionId)

        // Then: nil이 반환되어야 함
        XCTAssertNil(fetchedSession)
    }

    func test_fetchPracticeSessions_whenSessionsExist_thenReturnsAllSessions() throws {
        // Given: Script와 여러 PracticeSession이 존재할 때
        let createdScript = try createTestScript()
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
        let createdScript = try createTestScript()
        let scriptId = createdScript.id!

        // When: 해당 Script ID로 PracticeSession을 조회했을 때
        let fetchedSessions = try sut.fetchPracticeSessions(forScriptId: scriptId)

        // Then: 빈 배열이 반환되어야 함
        XCTAssertTrue(fetchedSessions.isEmpty)
    }
    
    // MARK: - FeedbackSummary Create Tests

    func test_createFeedbackSummary_whenValidDataProvided_thenCreatesSuccessfully() throws {
        // Given: Script와 PracticeSession이 존재하고 유효한 FeedbackSummary 데이터가 있을 때
        let createdScript = try createTestScript()
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

        // When: FeedbackSummary를 생성했을 때
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
        )) { error in
            XCTAssertEqual(
                (error as? ScriptRepositoryError)?.errorDescription,
                ScriptRepositoryError.notFound(message: "PracticeSession with ID \(nonExistentPracticeSessionId) not found.").errorDescription
            )
        }
    }

    func test_createFeedbackSummary_whenFeedbackSummaryAlreadyExists_thenThrowsError() throws {
        // Given: 이미 FeedbackSummary가 존재하는 PracticeSession이 있을 때
        let createdScript = try createTestScript()
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
        )) { error in
            XCTAssertEqual(
                (error as? ScriptRepositoryError)?.errorDescription,
                ScriptRepositoryError.validationError(message: "FeedbackSummary already exists for PracticeSession ID \(createdSession.id!).").errorDescription
            )
        }
    }

    func test_createFeedbackSummary_whenFeedbackDetailsDataIsEmpty_thenThrowsError() throws {
        // Given: Script와 PracticeSession이 존재하지만 feedbackDetailsData가 비어있을 때
        let createdScript = try createTestScript()
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
        )) { error in
            XCTAssertEqual(
                (error as? ScriptRepositoryError)?.errorDescription,
                ScriptRepositoryError.validationError(message: "FeedbackSummary must contain at least one FeedbackDetail.").errorDescription
            )
        }
    }
    
    // MARK: - Feedback Read Tests

    func test_fetchFeedbackSummary_whenSummaryExists_thenReturnsSummary() throws {
        // Given: FeedbackSummary가 존재하는 PracticeSession이 있을 때
        let createdScript = try createTestScript()
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
        // Given: FeedbackSummary가 존재하지 않는 PracticeSession이 있을 때
        let createdScript = try createTestScript()
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
        let createdScript = try createTestScript()
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
