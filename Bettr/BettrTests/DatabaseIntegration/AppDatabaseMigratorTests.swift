import Foundation
import GRDB
import XCTest
@testable import Bettr

final class AppDatabaseMigratorTests: XCTestCase {
    func test_migrate_whenDatabaseIsEmpty_thenCreatesCurrentSchemaAndRecordsMigration() throws {
        let dbQueue = try DatabaseQueue()

        try AppDatabaseMigrator.migrate(dbQueue)
        try AppDatabaseMigrator.migrate(dbQueue)

        try dbQueue.read { db in
            let tableNames = try String.fetchAll(
                db,
                sql: "SELECT name FROM sqlite_master WHERE type = 'table' ORDER BY name"
            )
            let wordScriptIndexCount = try Int.fetchOne(
                db,
                sql: "SELECT COUNT(*) FROM sqlite_master WHERE type = 'index' AND tbl_name = 'word' AND sql LIKE '%scriptId%'"
            )

            XCTAssertTrue(
                Set(["script", "sentence", "chunk", "feedback_summary", "feedback_detail", "word", "grdb_migrations"])
                    .isSubset(of: Set(tableNames))
            )
            XCTAssertEqual(wordScriptIndexCount, 1)
            XCTAssertEqual(
                try AppDatabaseMigrator.migrator.appliedIdentifiers(db),
                [AppDatabaseMigrator.initialSchemaMigration]
            )
            XCTAssertNoThrow(try db.checkForeignKeys())
        }
    }

    func test_migrate_whenLegacyDatabaseExists_thenPreservesDataAndRecordsMigration() throws {
        let databaseURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("AppDatabaseMigratorTests-\(UUID().uuidString).sqlite")
        defer { try? FileManager.default.removeItem(at: databaseURL) }

        try makeLegacyDatabase(at: databaseURL)

        let dbQueue = try DatabaseQueue(path: databaseURL.path)
        try AppDatabaseMigrator.migrate(dbQueue)

        try dbQueue.read { db in
            XCTAssertEqual(try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM script"), 1)
            XCTAssertEqual(try String.fetchOne(db, sql: "SELECT title FROM script WHERE id = 1"), "Legacy script")
            XCTAssertEqual(try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM sentence"), 1)
            XCTAssertEqual(try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM chunk"), 1)
            XCTAssertEqual(try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM feedback_summary"), 1)
            XCTAssertEqual(try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM feedback_detail"), 1)
            XCTAssertEqual(try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM word"), 1)
            XCTAssertEqual(
                try AppDatabaseMigrator.migrator.appliedIdentifiers(db),
                [AppDatabaseMigrator.initialSchemaMigration]
            )
            XCTAssertNoThrow(try db.checkForeignKeys())
        }
    }

    private func makeLegacyDatabase(at databaseURL: URL) throws {
        let dbQueue = try DatabaseQueue(path: databaseURL.path)

        try dbQueue.write { db in
            try db.execute(sql: """
                CREATE TABLE script (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    title TEXT NOT NULL,
                    createdAt DATETIME NOT NULL,
                    lastViewedAt DATETIME NOT NULL
                );
                CREATE TABLE sentence (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    scriptId INTEGER NOT NULL REFERENCES script(id) ON DELETE CASCADE,
                    orderIndex INTEGER NOT NULL,
                    englishText TEXT NOT NULL,
                    koreanText TEXT NOT NULL
                );
                CREATE TABLE chunk (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    sentenceId INTEGER NOT NULL REFERENCES sentence(id) ON DELETE CASCADE,
                    orderIndex INTEGER NOT NULL,
                    englishText TEXT NOT NULL,
                    koreanText TEXT NOT NULL
                );
                CREATE TABLE feedback_summary (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    scriptId INTEGER NOT NULL REFERENCES script(id) ON DELETE CASCADE,
                    accuracy DOUBLE NOT NULL,
                    missingWordCount INTEGER NOT NULL,
                    addedWordCount INTEGER NOT NULL,
                    replacedWordCount INTEGER NOT NULL,
                    practiceDuration DOUBLE NOT NULL,
                    createdAt DATETIME NOT NULL
                );
                CREATE TABLE feedback_detail (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    feedbackSummaryId INTEGER NOT NULL REFERENCES feedback_summary(id) ON DELETE CASCADE,
                    wordDiffType TEXT NOT NULL,
                    wordDiffExpected TEXT,
                    wordDiffActual TEXT,
                    originalText TEXT,
                    sentenceIndex INTEGER NOT NULL,
                    wordIndex INTEGER NOT NULL
                );
                CREATE TABLE word (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    scriptId INTEGER NOT NULL REFERENCES script(id) ON DELETE CASCADE,
                    lemma TEXT NOT NULL,
                    pos TEXT NOT NULL,
                    meaning TEXT NOT NULL,
                    orderIndex INTEGER NOT NULL
                );
                CREATE INDEX index_word_on_scriptId ON word(scriptId);
                """)

            try db.execute(sql: "INSERT INTO script VALUES (1, 'Legacy script', '2025-01-01 00:00:00', '2025-01-01 00:00:00')")
            try db.execute(sql: "INSERT INTO sentence VALUES (1, 1, 0, 'Legacy sentence', '기존 문장')")
            try db.execute(sql: "INSERT INTO chunk VALUES (1, 1, 0, 'Legacy chunk', '기존 청크')")
            try db.execute(sql: "INSERT INTO feedback_summary VALUES (1, 1, 0.8, 1, 0, 0, 10, '2025-01-01 00:00:00')")
            try db.execute(sql: "INSERT INTO feedback_detail VALUES (1, 1, 'missing', 'word', NULL, 'word', 0, 0)")
            try db.execute(sql: "INSERT INTO word VALUES (1, 1, 'legacy', '명', '기존', 0)")
        }
    }
}
