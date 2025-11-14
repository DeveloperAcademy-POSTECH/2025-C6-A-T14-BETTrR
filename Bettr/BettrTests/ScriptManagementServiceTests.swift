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
        try! DatabaseMigrator.setupDatabase(dbQueue)
        scriptRepository = ScriptRepository(dbQueue: dbQueue)
        sut = ScriptManagementService(scriptRepository: scriptRepository)
    }
    
    override func tearDown() {
        sut = nil
        scriptRepository = nil
        dbQueue = nil
        super.tearDown()
    }

    // MARK: - Script Create Tests
    
    func test_createScript_whenValidScriptDataProvided_thenScriptIsCreatedSuccessfully() async throws {
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
        let createdScript = try await sut.createScript(scriptData: scriptData)
        
        // Then: Script가 성공적으로 생성되어야 함
        XCTAssertNotNil(createdScript.id)
        XCTAssertEqual(createdScript.title, "Test Script")
        XCTAssertNotNil(createdScript.createdAt)
        XCTAssertNotNil(createdScript.lastViewedAt)
    }
    
    func test_createScript_whenScriptCreated_thenScriptExistsInDatabase() async throws {
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
        let createdScript = try await sut.createScript(scriptData: scriptData)
        
        // Then: 데이터베이스에 Script가 존재해야 함
        let fetchedScript = try await dbQueue.read { db in
            try Script.fetchOne(db, key: createdScript.id)
        }
        
        XCTAssertNotNil(fetchedScript)
        XCTAssertEqual(fetchedScript?.title, "Database Test Script")
    }
    
    func test_createScript_whenSentencesProvided_thenSentencesAreCreatedWithCorrectOrder() async throws {
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
        let createdScript = try await sut.createScript(scriptData: scriptData)
        
        // Then: Sentence들이 올바른 순서로 생성되어야 함
        let sentences = try await dbQueue.read { db in
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
    
    func test_createScript_whenChunksProvided_thenChunksAreCreatedWithCorrectOrder() async throws {
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
        let createdScript = try await sut.createScript(scriptData: scriptData)
        
        // Then: Chunk들이 올바른 순서로 생성되어야 함
        let sentence = try await dbQueue.read { db in
            try Sentence
                .filter(Column("scriptId") == createdScript.id!)
                .fetchOne(db)
        }
        
        let chunks = try await dbQueue.read { db in
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
    
    func test_createScript_whenComplexDataProvided_thenAllRelationshipsAreCreatedCorrectly() async throws {
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
        let createdScript = try await sut.createScript(scriptData: scriptData)
        
        // Then: 모든 관계가 올바르게 생성되어야 함
        let scriptCount = try await dbQueue.read { db in
            try Script.fetchCount(db)
        }
        let sentenceCount = try await dbQueue.read { db in
            try Sentence.filter(Column("scriptId") == createdScript.id!).fetchCount(db)
        }
        let chunkCount = try await dbQueue.read { db in
            try Chunk.fetchCount(db)
        }
        
        XCTAssertEqual(scriptCount, 1)
        XCTAssertEqual(sentenceCount, 2)
        XCTAssertEqual(chunkCount, 4)
    }
    
    func test_createScript_whenEmptySentences_thenThrowsError() async throws {
        // Given: 문장이 없는 ScriptData가 존재할 때
        let scriptData = ScriptData(
            title: "Empty Script",
            sentences: []
        )
        
        // When-Then: Script 생성 시 오류가 발생해야 함
        do {
            _ = try await sut.createScript(scriptData: scriptData)
            XCTFail("Expected validationError, but no error was thrown.")
        } catch {
            XCTAssertEqual(
                (error as? ScriptRepositoryError)?.errorDescription,
                ScriptRepositoryError.validationError(message: "A Script must contain at least one sentence.").errorDescription
            )
        }
    }
    
    func test_createScript_whenEmptyChunks_thenThrowsError() async throws {
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
        do {
            _ = try await sut.createScript(scriptData: scriptData)
            XCTFail("Expected validationError, but no error was thrown.")
        } catch {
            XCTAssertEqual(
                (error as? ScriptRepositoryError)?.errorDescription,
                ScriptRepositoryError.validationError(message: "A Sentence must contain at least one chunk.").errorDescription
            )
        }
    }
    
    // MARK: - Script Read Tests
    
    func test_fetchScript_whenScriptExists_thenReturnsScript() async throws {
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
        let createdScript = try await sut.createScript(scriptData: scriptData)
        
        // When: 해당 Script ID로 조회했을 때
        let fetchedScript = try await sut.fetchScript(id: createdScript.id!)
        
        // Then: 올바른 Script가 반환되어야 함
        XCTAssertNotNil(fetchedScript)
        XCTAssertEqual(fetchedScript?.title, "Fetchable Script")
        XCTAssertEqual(fetchedScript?.id, createdScript.id)
    }
    
    func test_fetchScript_whenScriptDoesNotExist_thenReturnsNil() async throws {
        // Given: 존재하지 않는 Script ID가 있을 때
        let nonExistentId: Int64 = 9999
        
        // When: 해당 ID로 Script를 조회했을 때
        let fetchedScript = try await sut.fetchScript(id: nonExistentId)
        
        // Then: nil이 반환되어야 함
        XCTAssertNil(fetchedScript)
    }
    
    func test_fetchAllScripts_whenScriptsExist_thenReturnsAllScripts() async throws {
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
        _ = try await sut.createScript(scriptData: scriptData1)
        _ = try await sut.createScript(scriptData: scriptData2)
        
        // When: 모든 Script를 조회했을 때
        let allScripts = try await sut.fetchAllScripts()
        
        // Then: 모든 Script가 반환되어야 함
        XCTAssertEqual(allScripts.count, 2)
        XCTAssertTrue(allScripts.contains(where: { $0.title == "Script One" }))
        XCTAssertTrue(allScripts.contains(where: { $0.title == "Script Two" }))
    }
    
    func test_fetchAllScripts_whenNoScriptsExist_thenReturnsEmptyArray() async throws {
        // Given: 데이터베이스에 Script가 없을 때
        
        // When: 모든 Script를 조회했을 때
        let allScripts = try await sut.fetchAllScripts()
        
        // Then: 빈 배열이 반환되어야 함
        XCTAssertTrue(allScripts.isEmpty)
    }

    // MARK: - Script Read with Relations Tests

    func test_fetchScriptWithSentences_whenScriptExistsWithSentences_thenReturnsScriptAndSentences() async throws {
        // Given: 여러 문장을 포함한 Script가 존재할 때
        let scriptData = ScriptData(
            title: "Script with Sentences",
            sentences: [
                SentenceData(
                    orderIndex: 0,
                    englishText: "First sentence.",
                    koreanText: "첫 번째 문장.",
                    chunks: [ChunkData(orderIndex: 0, englishText: "First", koreanText: "첫 번째")]
                ),
                SentenceData(
                    orderIndex: 1,
                    englishText: "Second sentence.",
                    koreanText: "두 번째 문장.",
                    chunks: [ChunkData(orderIndex: 0, englishText: "Second", koreanText: "두 번째")]
                )
            ]
        )
        let createdScript = try await sut.createScript(scriptData: scriptData)

        // When: Script와 연관된 Sentence들을 함께 조회했을 때
        let result = try await sut.fetchScriptWithSentences(id: createdScript.id!)

        // Then: Script와 Sentence들이 올바르게 반환되어야 함
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.script.id, createdScript.id)
        XCTAssertEqual(result?.script.title, "Script with Sentences")
        XCTAssertEqual(result?.sentences.count, 2)
        XCTAssertEqual(result?.sentences[0].englishText, "First sentence.")
        XCTAssertEqual(result?.sentences[1].englishText, "Second sentence.")
    }

    func test_fetchScriptWithSentences_whenScriptDoesNotExist_thenReturnsNil() async throws {
        // Given: 존재하지 않는 Script ID가 있을 때
        let nonExistentId: Int64 = 9999

        // When: 해당 ID로 Script와 Sentence들을 조회했을 때
        let result = try await sut.fetchScriptWithSentences(id: nonExistentId)

        // Then: nil이 반환되어야 함
        XCTAssertNil(result)
    }

    func test_fetchScriptWithSentencesAndChunks_whenScriptExistsWithSentencesAndChunks_thenReturnsScriptSentencesAndChunks() async throws {
        // Given: 여러 문장과 청크를 포함한 Script가 존재할 때
        let scriptData = ScriptData(
            title: "Script with Sentences and Chunks",
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
            ]
        )
        let createdScript = try await sut.createScript(scriptData: scriptData)

        // When: Script, Sentence, Chunk들을 함께 조회했을 때
        let result = try await sut.fetchScriptWithSentencesAndChunks(id: createdScript.id!)

        // Then: Script, Sentence, Chunk들이 올바르게 반환되어야 함
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.script.id, createdScript.id)
        XCTAssertEqual(result?.script.title, "Script with Sentences and Chunks")
        XCTAssertEqual(result?.sentences.count, 2)

        // 첫 번째 문장 검증
        XCTAssertEqual(result?.sentences[0].sentence.englishText, "Hello world.")
        XCTAssertEqual(result?.sentences[0].chunks.count, 2)
        XCTAssertEqual(result?.sentences[0].chunks[0].englishText, "Hello")
        XCTAssertEqual(result?.sentences[0].chunks[1].englishText, "world")

        // 두 번째 문장 검증
        XCTAssertEqual(result?.sentences[1].sentence.englishText, "How are you?")
        XCTAssertEqual(result?.sentences[1].chunks.count, 3)
        XCTAssertEqual(result?.sentences[1].chunks[0].englishText, "How")
        XCTAssertEqual(result?.sentences[1].chunks[1].englishText, "are")
        XCTAssertEqual(result?.sentences[1].chunks[2].englishText, "you")
    }

    func test_fetchScriptWithSentencesAndChunks_whenScriptDoesNotExist_thenReturnsNil() async throws {
        // Given: 존재하지 않는 Script ID가 있을 때
        let nonExistentId: Int64 = 9999

        // When: 해당 ID로 Script, Sentence, Chunk들을 조회했을 때
        let result = try await sut.fetchScriptWithSentencesAndChunks(id: nonExistentId)

        // Then: nil이 반환되어야 함
        XCTAssertNil(result)
    }

    // MARK: - Script Update Tests

    func test_updateLastViewedAt_whenScriptExists_thenUpdatesTimestamp() async throws {
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
        let createdScript = try await sut.createScript(scriptData: scriptData)
        let initialLastViewedAt = createdScript.lastViewedAt

        // When: lastViewedAt을 갱신했을 때
        try await Task.sleep(nanoseconds: 10_000_000) // 0.01초
        try await sut.updateLastViewedAt(forScriptId: createdScript.id!)

        // Then: 타임스탬프가 업데이트되어야 함
        let updatedScript = try await sut.fetchScript(id: createdScript.id!)
        XCTAssertNotNil(updatedScript)
        XCTAssertNotEqual(updatedScript?.lastViewedAt, initialLastViewedAt)
        XCTAssertTrue(updatedScript!.lastViewedAt > initialLastViewedAt)
    }

    func test_updateLastViewedAt_whenScriptDoesNotExist_thenThrowsError() async throws {
        // Given: 존재하지 않는 Script ID가 있을 때
        let nonExistentId: Int64 = 9999

        // When-Then: 업데이트 시 notFound 오류가 발생해야 함
        do {
            try await sut.updateLastViewedAt(forScriptId: nonExistentId)
            XCTFail("Expected notFound error, but no error was thrown.")
        } catch {
            XCTAssertEqual(
                (error as? ScriptRepositoryError)?.errorDescription,
                ScriptRepositoryError.notFound(message: "Script with ID \(nonExistentId) not found.").errorDescription
            )
        }
    }
    
    func test_updateScriptTitle_whenScriptExists_thenUpdatesTitle() async throws {
        // Given: Script가 존재할 때
        let scriptData = ScriptData(
            title: "Original Title",
            sentences: [
                SentenceData(
                    orderIndex: 0,
                    englishText: "Sentence.",
                    koreanText: "문장.",
                    chunks: [ChunkData(orderIndex: 0, englishText: "Chunk", koreanText: "청크")]
                )
            ]
        )
        let createdScript = try await sut.createScript(scriptData: scriptData)
        let newTitle = "Updated Title"
        
        // When: Script 제목을 갱신했을 때
        try await sut.updateScriptTitle(scriptId: createdScript.id!, newTitle: newTitle)
        
        // Then: 제목이 올바르게 업데이트되어야 함
        let updatedScript = try await sut.fetchScript(id: createdScript.id!)
        XCTAssertNotNil(updatedScript)
        XCTAssertEqual(updatedScript?.title, newTitle)
    }
    
    func test_updateScriptTitle_whenScriptDoesNotExist_thenThrowsError() async throws {
        // Given: 존재하지 않는 Script ID가 있을 때
        let nonExistentId: Int64 = 9999
        let newTitle = "Any Title"
        
        // When-Then: 업데이트 시 notFound 오류가 발생해야 함
        do {
            try await sut.updateScriptTitle(scriptId: nonExistentId, newTitle: newTitle)
            XCTFail("Expected notFound error, but no error was thrown.")
        } catch {
            XCTAssertEqual(
                (error as? ScriptRepositoryError)?.errorDescription,
                ScriptRepositoryError.notFound(message: "Script with ID \(nonExistentId) not found.").errorDescription
            )
        }
    }

    // MARK: - Script Delete Tests

    func test_deleteScript_whenScriptExists_thenDeletesScriptAndAllRelatedEntities() async throws {
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
        let createdScript = try await sut.createScript(scriptData: scriptData)
        let scriptId = createdScript.id!

        // When: Script를 삭제했을 때
        try await sut.deleteScript(id: scriptId)

        // Then: Script와 모든 연관 엔티티들이 삭제되어야 함
        let fetchedScript = try await sut.fetchScript(id: scriptId)
        XCTAssertNil(fetchedScript)

        let sentenceCount = try await dbQueue.read { db in
            try Sentence.filter(Column("scriptId") == scriptId).fetchCount(db)
        }
        XCTAssertEqual(sentenceCount, 0)

        let chunkCount = try await dbQueue.read { db in
            try Chunk.fetchCount(db)
        }
        XCTAssertEqual(chunkCount, 0)
    }

    // MARK: - Feedback Create Tests
    
    func test_createFeedbackSummary_withWordDiffDetails_thenDetailsAreSavedCorrectly() async throws {
        // Given: 스크립트와 피드백 상세 데이터
        let scriptData = ScriptData(
            title: "Feedback Test Script",
            sentences: [
                SentenceData(
                    orderIndex: 0,
                    englishText: "Hello world.",
                    koreanText: "안녕 세상.",
                    chunks: [
                        ChunkData(orderIndex: 0, englishText: "Hello", koreanText: "안녕"),
                        ChunkData(orderIndex: 1, englishText: "world", koreanText: "세상")
                    ]
                )
            ]
        )
        let createdScript = try await sut.createScript(scriptData: scriptData)
        
        let feedbackDetailsData: [(
            wordDiff: WordDiff,
            originalText: String?,
            sentenceIndex: Int,
            wordIndex: Int
        )] = [
            (
                wordDiff: .missing(expected: "world"),
                originalText: "world",
                sentenceIndex: 0,
                wordIndex: 1
            ),
            (
                wordDiff: .extra(actual: "beautiful"),
                originalText: nil,
                sentenceIndex: 0,
                wordIndex: 2
            ),
            (
                wordDiff: .replaced(expected: "Hello", actual: "Hi"),
                originalText: "Hello",
                sentenceIndex: 0,
                wordIndex: 0
            )
        ]
        
        // When: 피드백 요약을 생성했을 때
        let summary = try await sut.createFeedbackSummary(
            scriptId: createdScript.id!,
            accuracy: 0.7,
            missingWordCount: 1,
            addedWordCount: 1,
            replacedWordCount: 1,
            practiceDuration: 10.0,
            feedbackDetailsData: feedbackDetailsData
        )
        
        // Then: FeedbackDetail이 올바르게 저장되어야 함
        let fetchedDetails = try await sut.fetchFeedbackDetails(forFeedbackSummaryId: summary.id!)
        
        XCTAssertEqual(fetchedDetails.count, 3)
        
        // Missing Word 검증
        let missingDetail = fetchedDetails.first { $0.wordDiffType == "missing" }
        XCTAssertNotNil(missingDetail)
        XCTAssertEqual(missingDetail?.wordDiff, .missing(expected: "world"))
        XCTAssertEqual(missingDetail?.originalText, "world")
        XCTAssertEqual(missingDetail?.sentenceIndex, 0)
        XCTAssertEqual(missingDetail?.wordIndex, 1)
        
        // Extra Word 검증
        let extraDetail = fetchedDetails.first { $0.wordDiffType == "extra" }
        XCTAssertNotNil(extraDetail)
        XCTAssertEqual(extraDetail?.wordDiff, .extra(actual: "beautiful"))
        XCTAssertNil(extraDetail?.originalText)
        XCTAssertEqual(extraDetail?.sentenceIndex, 0)
        XCTAssertEqual(extraDetail?.wordIndex, 2)
        
        // Replaced Word 검증
        let replacedDetail = fetchedDetails.first { $0.wordDiffType == "replaced" }
        XCTAssertNotNil(replacedDetail)
        XCTAssertEqual(replacedDetail?.wordDiff, .replaced(expected: "Hello", actual: "Hi"))
        XCTAssertEqual(replacedDetail?.originalText, "Hello")
        XCTAssertEqual(replacedDetail?.sentenceIndex, 0)
        XCTAssertEqual(replacedDetail?.wordIndex, 0)
    }
}
