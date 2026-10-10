import GRDB
import XCTest
@testable import Bettr

@MainActor
final class ScriptConfirmIntegrationTests: XCTestCase {
    func test_composedWorkflowPersistsGraphAndSuppliesOneCompletion() async throws {
        let database = try AppDatabase.makeInMemory()
        let analyzer = IntegrationScriptAnalyzer()
        let clock = ScriptConfirmTestClock()
        defer { clock.finishPending() }
        let composition = try PreviewComposition.make(database: database, analyzer: analyzer)
        let model = composition.makeScriptConfirmViewModel(clock: clock)

        await model.start(content: "Hello world.", title: "User title")
        let result = try XCTUnwrap(model.consumeCompletion())
        XCTAssertEqual(result.title, "User title")
        XCTAssertNil(model.consumeCompletion())
        await model.start(content: "Duplicate", title: "Other")
        await model.retrySaving()

        let home = composition.makeHomeListModel()
        await home.refresh()
        XCTAssertEqual(home.scripts?.map(\.id), [result.savedID])
        XCTAssertEqual(home.scripts?.map(\.title), ["User title"])
        let savedID = result.savedID
        let sentences = try await database.dbQueue.read { db in
            try Sentence.filter(Column("scriptId") == savedID).fetchAll(db)
        }
        XCTAssertEqual(sentences.map(\.englishText), ["Hello world."])
        let sentenceID = try XCTUnwrap(sentences.first?.id)
        let chunks = try await database.dbQueue.read { db in
            try Chunk.filter(Column("sentenceId") == sentenceID).order(Column("orderIndex")).fetchAll(db)
        }
        XCTAssertEqual(chunks.map(\.englishText), ["Hello", "world."])
        XCTAssertEqual(analyzer.inputs, ["Hello world."])
    }

    func test_rolledBackTransactionRetriesDraftWithoutAdditionalAI() async throws {
        let database = try AppDatabase.makeInMemory()
        let analyzer = IntegrationScriptAnalyzer()
        let clock = ScriptConfirmTestClock()
        defer { clock.finishPending() }
        let composition = try PreviewComposition.make(database: database, analyzer: analyzer)
        let model = composition.makeScriptConfirmViewModel(clock: clock)
        // 하위 레코드 저장 실패도 상위 Script를 포함한 단일 transaction을 rollback합니다.
        try await database.dbQueue.write { db in
            try db.execute(sql: """
                CREATE TRIGGER fail_chunk BEFORE INSERT ON chunk
                BEGIN SELECT RAISE(ABORT, 'fixture storage failure'); END;
                """)
        }

        await model.start(content: "Hello world.", title: "")
        XCTAssertTrue(model.canRetrySaving)
        XCTAssertNotNil(model.errorMessage)
        let countAfterFailure = try await database.dbQueue.read { db in try Script.fetchCount(db) }
        XCTAssertEqual(countAfterFailure, 0)
        try await database.dbQueue.write { db in try db.execute(sql: "DROP TRIGGER fail_chunk") }

        await model.retrySaving()
        let result = try XCTUnwrap(model.consumeCompletion())
        XCTAssertEqual(result.title, "Analyzed title")
        XCTAssertFalse(model.canRetrySaving)
        XCTAssertNil(model.errorMessage)
        XCTAssertEqual(analyzer.inputs, ["Hello world."])
        let counts = try await database.dbQueue.read { db in
            (try Script.fetchCount(db), try Sentence.fetchCount(db), try Chunk.fetchCount(db))
        }
        XCTAssertEqual(counts.0, 1)
        XCTAssertEqual(counts.1, 1)
        XCTAssertEqual(counts.2, 2)
    }
}

@MainActor
private final class IntegrationScriptAnalyzer: ScriptAnalyzing {
    private(set) var inputs: [String] = []

    func analyzeScript(_ content: String) async throws -> ScriptData {
        inputs.append(content)
        return ScriptData(title: "Analyzed title", sentences: [
            SentenceData(orderIndex: 0, englishText: "Hello world.", koreanText: "안녕 세상.", chunks: [
                ChunkData(orderIndex: 0, englishText: "Hello", koreanText: "안녕"),
                ChunkData(orderIndex: 1, englishText: "world.", koreanText: "세상.")
            ])
        ])
    }
}
