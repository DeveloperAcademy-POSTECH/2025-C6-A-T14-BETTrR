import XCTest
import GRDB
@testable import Bettr

final class ScriptManagementServiceTests: XCTestCase {
    var sut: ScriptManagementService!
    var scriptRepository: ScriptRepository!
    var dbQueue: DatabaseQueue!
    
    override func setUp() {
        super.setUp()
        
        dbQueue = try! DatabaseQueue()
        try! setupDatabase(dbQueue)
        scriptRepository = ScriptRepository()
        sut = ScriptManagementService(dbQueue: dbQueue, scriptRepository: scriptRepository)
    }
    
    override func tearDown() {
        sut = nil
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
    
    func test_createScript_whenEmptySentences_thenThrowsError() throws {
        // Given: 문장이 없는 ScriptData가 존재할 때
        let scriptData = ScriptData(
            title: "Empty Script",
            sentences: []
        )
        
        // When-Then: Script 생성 시 오류가 발생해야 함
        XCTAssertThrowsError(try sut.createScript(scriptData: scriptData)) { error in
            XCTAssertEqual(
                (error as? ScriptRepositoryError)?.errorDescription,
                ScriptRepositoryError.validationError(message: "A Script must contain at least one sentence.").errorDescription
            )
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
        XCTAssertThrowsError(try sut.createScript(scriptData: scriptData)) { error in
            XCTAssertEqual(
                (error as? ScriptRepositoryError)?.errorDescription,
                ScriptRepositoryError.validationError(message: "A Sentence must contain at least one chunk.").errorDescription
            )
        }
    }
    
    // MARK: - Script Read Tests
    
    func test_fetchScript_whenScriptExists_thenReturnsScript() throws {
        // Given: Script가 존재할 때
        let scriptData = ScriptData(
            title: "Fetchable Script",
            sentences: [
                SentenceData(
                    orderIndex: 0,
                    englishText: "A sentence.",
                    koreanText: "문장.",
                    chunks: [ChunkData(orderIndex: 0, englishText: "Dummy", koreanText: "더미")]
                )
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
                SentenceData(
                    orderIndex: 0,
                    englishText: "S1.",
                    koreanText: "S1.",
                    chunks: [ChunkData(orderIndex: 0, englishText: "Dummy1", koreanText: "더미1")]
                )
            ]
        )
        let scriptData2 = ScriptData(
            title: "Script Two",
            sentences: [
                SentenceData(
                    orderIndex: 0,
                    englishText: "S2.",
                    koreanText: "S2.",
                    chunks: [ChunkData(orderIndex: 0, englishText: "Dummy2", koreanText: "더미2")]
                )
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
                SentenceData(
                    orderIndex: 0,
                    englishText: "Sentence.",
                    koreanText: "문장.",
                    chunks: [ChunkData(orderIndex: 0, englishText: "Chunk", koreanText: "청크")]
                )
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
        XCTAssertThrowsError(try sut.updateLastViewedAt(forScriptId: nonExistentId)) { error in
            XCTAssertEqual(
                (error as? ScriptRepositoryError)?.errorDescription,
                ScriptRepositoryError.notFound(message: "Script with ID \(nonExistentId) not found.").errorDescription
            )
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
    }

    func test_deleteScript_whenScriptDoesNotExist_thenThrowsError() throws {
        // Given: 존재하지 않는 Script ID가 있을 때
        let nonExistentId: Int64 = 9999

        // When-Then: 삭제 시 notFound 오류가 발생해야 함
        XCTAssertThrowsError(try sut.deleteScript(id: nonExistentId)) { error in
            XCTAssertEqual(
                (error as? ScriptRepositoryError)?.errorDescription,
                ScriptRepositoryError.notFound(message: "Script with ID \(nonExistentId) not found.").errorDescription
            )
        }
    }
}
