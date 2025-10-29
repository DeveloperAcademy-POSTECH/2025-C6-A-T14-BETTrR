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
        }
    }
    
    // MARK: - Create Tests
    
    func test_createScript_whenValidScriptDataProvided_thenScriptIsCreatedSuccessfully() throws {
        // Given: 유효한 ScriptData가 주어졌을 때
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
        
        // When: createScript를 호출하면
        let createdScript = try sut.createScript(scriptData: scriptData)
        
        // Then: Script가 성공적으로 생성되어야 함
        XCTAssertNotNil(createdScript.id)
        XCTAssertEqual(createdScript.title, "Test Script")
        XCTAssertNotNil(createdScript.createdAt)
        XCTAssertNotNil(createdScript.lastViewedAt)
    }
    
    func test_createScript_whenScriptCreated_thenScriptExistsInDatabase() throws {
        // Given: ScriptData가 주어졌을 때
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
        
        // When: Script를 생성하면
        let createdScript = try sut.createScript(scriptData: scriptData)
        
        // Then: 데이터베이스에 Script가 존재해야 함
        let fetchedScript = try dbQueue.read { db in
            try Script.fetchOne(db, key: createdScript.id)
        }
        
        XCTAssertNotNil(fetchedScript)
        XCTAssertEqual(fetchedScript?.title, "Database Test Script")
    }
    
    func test_createScript_whenSentencesProvided_thenSentencesAreCreatedWithCorrectOrder() throws {
        // Given: 여러 문장을 포함한 ScriptData가 주어졌을 때
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
        
        // When: Script를 생성하면
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
        // Given: Chunk를 포함한 Sentence가 있는 ScriptData가 주어졌을 때
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
        
        // When: Script를 생성하면
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
        // Given: 복잡한 구조의 ScriptData가 주어졌을 때
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
        
        // When: Script를 생성하면
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
        // Given: 문장이 없는 ScriptData가 주어졌을 때
        let scriptData = ScriptData(
            title: "Empty Script",
            sentences: []
        )
        
        // When & Then: Script를 생성하려고 하면 오류가 발생해야 함
        XCTAssertThrowsError(try sut.createScript(scriptData: scriptData)) {
            error in
            XCTAssertEqual((error as? ScriptRepositoryError)?.errorDescription, ScriptRepositoryError.validationError(message: "A Script must contain at least one sentence.").errorDescription)
        }
    }
    
    func test_createScript_whenEmptyChunks_thenThrowsError() throws {
        // Given: ScriptData with a sentence that has an empty chunks array
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
        
        // When & Then: Attempting to create the script should throw a validation error
        XCTAssertThrowsError(try sut.createScript(scriptData: scriptData)) {
            error in
            XCTAssertEqual((error as? ScriptRepositoryError)?.errorDescription, ScriptRepositoryError.validationError(message: "A Sentence must contain at least one chunk.").errorDescription)
        }
    }
    
    // MARK: - Read Tests
    
    func test_fetchScript_whenScriptExists_thenReturnsScript() throws {
        // Given: A script is created
        let scriptData = ScriptData(
            title: "Fetchable Script",
            sentences: [
                SentenceData(orderIndex: 0, englishText: "A sentence.", koreanText: "문장.", chunks: [ChunkData(orderIndex: 0, englishText: "Dummy", koreanText: "더미")])
            ]
        )
        let createdScript = try sut.createScript(scriptData: scriptData)
        
        // When: Fetching the script by its ID
        let fetchedScript = try sut.fetchScript(id: createdScript.id!)
        
        // Then: The correct script should be returned
        XCTAssertNotNil(fetchedScript)
        XCTAssertEqual(fetchedScript?.title, "Fetchable Script")
        XCTAssertEqual(fetchedScript?.id, createdScript.id)
    }
    
    func test_fetchScript_whenScriptDoesNotExist_thenReturnsNil() throws {
        // Given: A non-existent script ID
        let nonExistentId: Int64 = 9999
        
        // When: Fetching a script with the non-existent ID
        let fetchedScript = try sut.fetchScript(id: nonExistentId)
        
        // Then: Nil should be returned
        XCTAssertNil(fetchedScript)
    }
    
    func test_fetchAllScripts_whenScriptsExist_thenReturnsAllScripts() throws {
        // Given: Multiple scripts are created
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
        
        // When: Fetching all scripts
        let allScripts = try sut.fetchAllScripts()
        
        // Then: All created scripts should be returned
        XCTAssertEqual(allScripts.count, 2)
        XCTAssertTrue(allScripts.contains(where: { $0.title == "Script One" }))
        XCTAssertTrue(allScripts.contains(where: { $0.title == "Script Two" }))
    }
    
    func test_fetchAllScripts_whenNoScriptsExist_thenReturnsEmptyArray() throws {
        // Given: No scripts exist in the database (default setup)
        
        // When: Fetching all scripts
        let allScripts = try sut.fetchAllScripts()
        
        // Then: An empty array should be returned
        XCTAssertTrue(allScripts.isEmpty)
    }

    // MARK: - Update Tests

    func test_updateLastViewedAt_whenScriptExists_thenUpdatesTimestamp() throws {
        // Given: A script is created
        let scriptData = ScriptData(
            title: "Script to Update",
            sentences: [
                SentenceData(orderIndex: 0, englishText: "Sentence.", koreanText: "문장.", chunks: [ChunkData(orderIndex: 0, englishText: "Chunk", koreanText: "청크")])
            ]
        )
        let createdScript = try sut.createScript(scriptData: scriptData)
        let initialLastViewedAt = createdScript.lastViewedAt

        // Simulate a small delay to ensure timestamp changes
        Thread.sleep(forTimeInterval: 0.01)

        // When: Updating lastViewedAt
        try sut.updateLastViewedAt(forScriptId: createdScript.id!)

        // Then: The script's lastViewedAt should be updated
        let updatedScript = try sut.fetchScript(id: createdScript.id!)
        XCTAssertNotNil(updatedScript)
        XCTAssertNotEqual(updatedScript?.lastViewedAt, initialLastViewedAt)
        XCTAssertTrue(updatedScript!.lastViewedAt > initialLastViewedAt)
    }

    func test_updateLastViewedAt_whenScriptDoesNotExist_thenThrowsError() throws {
        // Given: A non-existent script ID
        let nonExistentId: Int64 = 9999

        // When & Then: Attempting to update lastViewedAt for a non-existent script should throw an error
        XCTAssertThrowsError(try sut.updateLastViewedAt(forScriptId: nonExistentId)) {
            error in
            XCTAssertEqual((error as? ScriptRepositoryError)?.errorDescription, ScriptRepositoryError.notFound(message: "Script with ID \(nonExistentId) not found.").errorDescription)
        }
    }
}
