import GRDB
import XCTest
@testable import Bettr

final class AppDatabaseTests: XCTestCase {
    @MainActor
    func test_makeInMemory_whenWrapperIsReleasedSynchronously_thenRetainedQueueRemainsUsable() throws {
        var database: AppDatabase? = try AppDatabase.makeInMemory()
        weak var releasedDatabase: AppDatabase?
        releasedDatabase = database
        let dbQueue = try XCTUnwrap(database).dbQueue

        database = nil

        XCTAssertNil(releasedDatabase)
        try dbQueue.read { db in
            XCTAssertEqual(try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM script"), 0)
            XCTAssertNoThrow(try db.checkForeignKeys())
        }
    }
}
