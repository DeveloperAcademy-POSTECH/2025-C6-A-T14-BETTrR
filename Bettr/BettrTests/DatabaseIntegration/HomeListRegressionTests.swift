import Foundation
import XCTest
@testable import Bettr

@MainActor
final class HomeListRegressionTests: XCTestCase {
    func test_refreshScripts_whenScriptsExist_thenSortsByLastViewedAtDescending() async throws {
        let model = try makeModel()
        let oldest = try await saveScript(title: "Oldest", viewedAt: 100)
        let newest = try await saveScript(title: "Newest", viewedAt: 300)
        let middle = try await saveScript(title: "Middle", viewedAt: 200)

        await model.refresh()

        let scripts = try XCTUnwrap(model.scripts)
        XCTAssertEqual(scripts.map(\.id), [newest.id, middle.id, oldest.id])
    }

    func test_refreshScripts_whenDatabaseIsEmpty_thenPublishesSuccessfulEmptyList() async throws {
        let model = try makeModel()
        XCTAssertNil(model.scripts)

        await model.refresh()

        let scripts = try XCTUnwrap(model.scripts)
        XCTAssertTrue(scripts.isEmpty)
    }

    func test_refreshScripts_afterSuccessfulDeletion_thenRemovesDeletedScript() async throws {
        let model = try makeModel()
        let deleted = try await saveScript(title: "Deleted", viewedAt: 200)
        let remaining = try await saveScript(title: "Remaining", viewedAt: 100)
        await model.refresh()
        XCTAssertEqual(try XCTUnwrap(model.scripts).count, 2)

        await model.deleteScript(id: try XCTUnwrap(deleted.id))

        let scripts = try XCTUnwrap(model.scripts)
        XCTAssertEqual(scripts.map(\.id), [remaining.id])
    }

    private var repository: ScriptRepository!

    private func makeModel() throws -> HomeListModel {
        let database = try AppDatabase.makeInMemory()
        repository = ScriptRepository(dbQueue: database.dbQueue)
        let service = ScriptManagementService(scriptRepository: repository)
        return HomeListModel(scriptService: service)
    }

    private func saveScript(
        title: String,
        viewedAt: TimeInterval
    ) async throws -> Script {
        try await repository.save(script: Script(
            title: title,
            createdAt: Date(timeIntervalSince1970: 0),
            lastViewedAt: Date(timeIntervalSince1970: viewedAt)
        ))
    }
}
