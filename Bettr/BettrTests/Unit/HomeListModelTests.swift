import Foundation
import XCTest
@testable import Bettr

@MainActor
final class HomeListModelTests: XCTestCase {
    func test_refresh_whenInitialLoadFails_thenShowsErrorAndRetryLoadsList() async {
        let service = ControlledHomeScriptService()
        let model = HomeListModel(scriptService: service)
        XCTAssertNil(model.scripts)
        XCTAssertFalse(model.isLoading)

        let firstLoad = Task { await model.refresh() }
        await service.waitForFetch(1)
        XCTAssertTrue(model.isLoading)
        service.failFetch(1)
        await firstLoad.value

        XCTAssertNil(model.scripts)
        XCTAssertNotNil(model.errorMessage)
        XCTAssertFalse(model.isLoading)

        let retry = Task { await model.refresh() }
        await service.waitForFetch(2)
        service.completeFetch(2, scripts: [script(id: 1)])
        await retry.value

        XCTAssertEqual(model.scripts?.map(\.id), [1])
        XCTAssertNil(model.errorMessage)
        XCTAssertFalse(model.isLoading)
    }

    func test_refresh_whenReloadFails_thenRetainsCachedList() async {
        let service = ControlledHomeScriptService()
        let model = HomeListModel(scriptService: service)
        await load([script(id: 1)], into: model, service: service)

        let reload = Task { await model.refresh() }
        await service.waitForFetch(2)
        service.failFetch(2)
        await reload.value

        XCTAssertEqual(model.scripts?.map(\.id), [1])
        XCTAssertNotNil(model.errorMessage)
        XCTAssertFalse(model.isLoading)
    }

    func test_refresh_whenCancelledBeforeLateSuccess_thenDiscardsResultAndClearsLoading() async {
        let service = ControlledHomeScriptService()
        let model = HomeListModel(scriptService: service)
        let request = Task { await model.refresh() }
        await service.waitForFetch(1)

        request.cancel()
        service.completeFetch(1, scripts: [script(id: 1)])
        await request.value

        XCTAssertNil(model.scripts)
        XCTAssertNil(model.errorMessage)
        XCTAssertFalse(model.isLoading)
    }

    func test_refresh_whenRequestsOverlap_thenLatestRequestWins() async {
        let service = ControlledHomeScriptService()
        let model = HomeListModel(scriptService: service)
        let older = Task { await model.refresh() }
        await service.waitForFetch(1)
        let newer = Task { await model.refresh() }
        await service.waitForFetch(2)

        service.completeFetch(2, scripts: [script(id: 2)])
        await newer.value
        XCTAssertEqual(model.scripts?.map(\.id), [2])
        XCTAssertFalse(model.isLoading)

        service.completeFetch(1, scripts: [script(id: 1)])
        await older.value

        XCTAssertEqual(model.scripts?.map(\.id), [2])
        XCTAssertNil(model.errorMessage)
        XCTAssertFalse(model.isLoading)
    }

    func test_deleteScript_whenEarlierLoadFinishesLater_thenCannotRestoreDeletedRows() async {
        let service = ControlledHomeScriptService()
        let model = HomeListModel(scriptService: service)
        let deleted = script(id: 1)
        let remaining = script(id: 2)
        await load([deleted, remaining], into: model, service: service)

        let earlierLoad = Task { await model.refresh() }
        await service.waitForFetch(2)
        let deletion = Task { await model.deleteScript(id: 1) }
        await service.waitForDeletion(1)
        service.completeDeletion(1)
        await service.waitForFetch(3)
        service.completeFetch(3, scripts: [remaining])
        await deletion.value

        service.completeFetch(2, scripts: [deleted, remaining])
        await earlierLoad.value

        XCTAssertEqual(model.scripts?.map(\.id), [2])
        XCTAssertFalse(model.isDeleting)
        XCTAssertFalse(model.isLoading)
    }

    func test_refresh_whenDeletionIsSuspended_thenDoesNotStartAnotherFetch() async {
        let service = ControlledHomeScriptService()
        let model = HomeListModel(scriptService: service)
        await load([script(id: 1)], into: model, service: service)
        let deletion = Task { await model.deleteScript(id: 1) }
        await service.waitForDeletion(1)
        XCTAssertTrue(model.isDeleting)

        await model.refresh()

        XCTAssertEqual(service.fetchCount, 1)
        XCTAssertTrue(model.isDeleting)
        service.completeDeletion(1)
        await service.waitForFetch(2)
        service.completeFetch(2, scripts: [])
        await deletion.value

        XCTAssertTrue(model.scripts?.isEmpty == true)
        XCTAssertFalse(model.isDeleting)
        XCTAssertFalse(model.isLoading)
    }

    func test_deleteScript_whenDeletionFails_thenRetainsCachedListAndShowsError() async {
        let service = ControlledHomeScriptService()
        let model = HomeListModel(scriptService: service)
        await load([script(id: 1), script(id: 2)], into: model, service: service)
        let deletion = Task { await model.deleteScript(id: 1) }
        await service.waitForDeletion(1)

        service.failDeletion(1)
        await deletion.value

        XCTAssertEqual(model.scripts?.map(\.id), [1, 2])
        XCTAssertNotNil(model.errorMessage)
        XCTAssertEqual(service.fetchCount, 1)
        XCTAssertFalse(model.isDeleting)
        XCTAssertFalse(model.isLoading)
    }

    func test_deleteScript_whenDeletionSucceedsButReloadFails_thenDeletedRowStaysRemoved() async {
        let service = ControlledHomeScriptService()
        let model = HomeListModel(scriptService: service)
        await load([script(id: 1), script(id: 2)], into: model, service: service)
        let deletion = Task { await model.deleteScript(id: 1) }
        await service.waitForDeletion(1)

        service.completeDeletion(1)
        await service.waitForFetch(2)
        service.failFetch(2)
        await deletion.value

        XCTAssertEqual(model.scripts?.map(\.id), [2])
        XCTAssertNotNil(model.errorMessage)
        XCTAssertFalse(model.isDeleting)
        XCTAssertFalse(model.isLoading)
    }

    private func load(
        _ scripts: [Script],
        into model: HomeListModel,
        service: ControlledHomeScriptService
    ) async {
        let requestNumber = service.fetchCount + 1
        let request = Task { await model.refresh() }
        await service.waitForFetch(requestNumber)
        service.completeFetch(requestNumber, scripts: scripts)
        await request.value
    }

    private func script(id: Int64) -> Script {
        Script(
            id: id,
            title: "Script \(id)",
            createdAt: Date(timeIntervalSince1970: 0),
            lastViewedAt: Date(timeIntervalSince1970: 0)
        )
    }
}

@MainActor
private final class ControlledHomeScriptService: HomeScriptServicing {
    private(set) var fetchCount = 0
    private var deletionCount = 0
    private var fetches: [Int: CheckedContinuation<[Script], Error>] = [:]
    private var deletions: [Int: CheckedContinuation<Void, Error>] = [:]
    private var fetchWaiters: [Int: CheckedContinuation<Void, Never>] = [:]
    private var deletionWaiters: [Int: CheckedContinuation<Void, Never>] = [:]

    func fetchAllScripts() async throws -> [Script] {
        fetchCount += 1
        let requestNumber = fetchCount
        return try await withCheckedThrowingContinuation { continuation in
            fetches[requestNumber] = continuation
            fetchWaiters.removeValue(forKey: requestNumber)?.resume()
        }
    }

    func deleteScript(id: Int64) async throws {
        deletionCount += 1
        let requestNumber = deletionCount
        try await withCheckedThrowingContinuation { continuation in
            deletions[requestNumber] = continuation
            deletionWaiters.removeValue(forKey: requestNumber)?.resume()
        }
    }

    func waitForFetch(_ requestNumber: Int) async {
        guard fetchCount < requestNumber else { return }
        await withCheckedContinuation { continuation in
            fetchWaiters[requestNumber] = continuation
        }
    }

    func waitForDeletion(_ requestNumber: Int) async {
        guard deletionCount < requestNumber else { return }
        await withCheckedContinuation { continuation in
            deletionWaiters[requestNumber] = continuation
        }
    }

    func completeFetch(_ requestNumber: Int, scripts: [Script]) {
        fetches.removeValue(forKey: requestNumber)!.resume(returning: scripts)
    }

    func failFetch(_ requestNumber: Int) {
        fetches.removeValue(forKey: requestNumber)!.resume(throwing: HomeListTestError.failed)
    }

    func completeDeletion(_ requestNumber: Int) {
        deletions.removeValue(forKey: requestNumber)!.resume()
    }

    func failDeletion(_ requestNumber: Int) {
        deletions.removeValue(forKey: requestNumber)!.resume(throwing: HomeListTestError.failed)
    }
}

private enum HomeListTestError: Error {
    case failed
}
