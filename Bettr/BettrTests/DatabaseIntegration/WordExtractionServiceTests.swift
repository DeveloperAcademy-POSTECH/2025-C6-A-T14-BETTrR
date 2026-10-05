import GRDB
import XCTest
@testable import Bettr

@MainActor
final class WordExtractionServiceTests: XCTestCase {
    func test_extractAndSaveWords_whenExtractionSucceeds_thenPersistsWordsInOrder() async throws {
        let context = try await makeContext(
            words: [
                WordData(lemma: "encounter", pos: "동", meaning: "마주치다"),
                WordData(lemma: "challenge", pos: "명", meaning: "도전")
            ]
        )

        try await context.service.extractAndSaveWords(for: context.scriptId)
        let words = try await context.service.fetchWords(for: context.scriptId)

        XCTAssertEqual(context.extractor.callCount, 1)
        XCTAssertEqual(words.map(\.lemma), ["encounter", "challenge"])
        XCTAssertEqual(words.map(\.orderIndex), [0, 1])
    }

    func test_extractAndSaveWords_whenWordsAlreadyExist_thenBypassesAIExtraction() async throws {
        let context = try await makeContext(words: [
            WordData(lemma: "unused", pos: "형", meaning: "쓰지 않음")
        ])
        try await insertWord(
            Word(scriptId: context.scriptId, lemma: "cached", pos: "형", meaning: "저장됨", orderIndex: 0),
            context: context
        )

        try await context.service.extractAndSaveWords(for: context.scriptId)
        let words = try await context.service.fetchWords(for: context.scriptId)

        XCTAssertEqual(context.extractor.callCount, 0)
        XCTAssertEqual(words.map(\.lemma), ["cached"])
    }

    func test_extractAndSaveWords_whenAIThrowsTerminalError_thenPropagatesWithoutSaving() async throws {
        let context = try await makeContext(error: AIError.authentication)

        do {
            try await context.service.extractAndSaveWords(for: context.scriptId)
            XCTFail("Expected authentication error")
        } catch let error as AIError {
            XCTAssertEqual(error, .authentication)
        }

        let words = try await context.service.fetchWords(for: context.scriptId)
        XCTAssertEqual(context.extractor.callCount, 1)
        XCTAssertTrue(words.isEmpty)
    }

    func test_extractAndSaveWords_whenWordInsertFails_thenRollsBackWithoutRetryingAI() async throws {
        let context = try await makeContext(
            words: [
                WordData(lemma: "encounter", pos: "동", meaning: "마주치다"),
                WordData(lemma: "challenge", pos: "명", meaning: "도전")
            ]
        )
        try await context.dbQueue.write { db in
            try db.execute(sql: """
                CREATE TRIGGER fail_second_word
                BEFORE INSERT ON word
                WHEN NEW.orderIndex = 1
                BEGIN
                    SELECT RAISE(ABORT, 'forced word insert failure');
                END
                """)
        }

        do {
            try await context.service.extractAndSaveWords(for: context.scriptId)
            XCTFail("Expected word insert failure")
        } catch {
            XCTAssertTrue(error is DatabaseError, "Persistence failure must retain its storage error type")
        }

        let words = try await context.service.fetchWords(for: context.scriptId)
        XCTAssertEqual(context.extractor.callCount, 1)
        XCTAssertTrue(words.isEmpty)
    }

    func test_extractAndSaveWords_whenCancelledAfterExtractorReturns_thenDoesNotSaveLateSuccess() async throws {
        let context = try await makeContext(words: [
            WordData(lemma: "late", pos: "형", meaning: "늦은")
        ])
        var task: Task<Void, Error>!
        context.extractor.onExtract = {
            task.cancel()
        }

        task = Task {
            try await context.service.extractAndSaveWords(for: context.scriptId)
        }

        do {
            try await task.value
            XCTFail("Expected cancellation")
        } catch is CancellationError {
            // Expected from the service cancellation checkpoint after extraction.
        } catch AIError.cancelled {
            // Also acceptable if the extractor boundary observes cancellation first.
        }

        let words = try await context.service.fetchWords(for: context.scriptId)
        XCTAssertEqual(context.extractor.callCount, 1)
        XCTAssertTrue(words.isEmpty)
    }

    private func makeContext(
        words: [WordData] = [],
        error: Error? = nil
    ) async throws -> WordExtractionTestContext {
        let dbQueue = try DatabaseQueue()
        try AppDatabaseMigrator.migrate(dbQueue)
        let repository = ScriptRepository(dbQueue: dbQueue)
        let scriptService = ScriptManagementService(scriptRepository: repository)
        let script = try await scriptService.createScript(scriptData: Self.scriptData())
        let extractor = FakeWordExtractor(words: words, error: error)
        let service = WordExtractionService(
            dbQueue: dbQueue,
            scriptRepository: repository,
            scriptManagementService: scriptService,
            wordExtractor: extractor
        )

        return WordExtractionTestContext(
            dbQueue: dbQueue,
            repository: repository,
            service: service,
            extractor: extractor,
            scriptId: try XCTUnwrap(script.id)
        )
    }

    private func insertWord(_ word: Word, context: WordExtractionTestContext) async throws {
        try await context.dbQueue.write { db in
            var word = word
            _ = try context.repository.save(word: &word, in: db)
        }
    }

    private static func scriptData() -> ScriptData {
        ScriptData(
            title: "Word extraction script",
            sentences: [
                SentenceData(
                    orderIndex: 0,
                    englishText: "I encountered an enormous challenge.",
                    koreanText: "나는 거대한 도전에 마주쳤다.",
                    chunks: [
                        ChunkData(
                            orderIndex: 0,
                            englishText: "I encountered an enormous challenge.",
                            koreanText: "나는 거대한 도전에 마주쳤다."
                        )
                    ]
                )
            ]
        )
    }
}

private struct WordExtractionTestContext {
    let dbQueue: DatabaseQueue
    let repository: ScriptRepository
    let service: WordExtractionService
    let extractor: FakeWordExtractor
    let scriptId: Int64
}

@MainActor
private final class FakeWordExtractor: WordExtracting {
    private let words: [WordData]
    private let error: Error?
    private(set) var callCount = 0
    var onExtract: (() -> Void)?

    init(words: [WordData], error: Error?) {
        self.words = words
        self.error = error
    }

    func extractWords(from content: String) async throws -> [WordData] {
        callCount += 1
        onExtract?()

        if let error {
            throw error
        }

        return words
    }
}
