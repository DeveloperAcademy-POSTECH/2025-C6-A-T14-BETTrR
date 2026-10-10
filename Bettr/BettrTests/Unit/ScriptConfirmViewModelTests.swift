import Foundation
import Observation
import XCTest
@testable import Bettr

@MainActor
final class ScriptConfirmViewModelTests: XCTestCase {
    func test_successUsesFrozenInputAndTitleAndCompletesOnlyOnce() async {
        let fixture = Fixture()
        defer { fixture.finishPending() }
        var content = "Original content"
        var title = "User title"
        let task = fixture.start(content: content, title: title)
        await waitUntil { fixture.analyzer.inputs.count == 1 && fixture.clock.deadlines.count == 1 }
        content = "Edited content"
        title = "Edited title"
        XCTAssertTrue(fixture.model.isAnalyzing)
        XCTAssertFalse(fixture.model.canEdit)
        XCTAssertEqual(fixture.analyzer.inputs, ["Original content"])
        XCTAssertEqual(fixture.limiter.dates, [fixture.clock.date])
        XCTAssertEqual(fixture.clock.deadlines[0], fixture.clock.origin.advanced(by: .seconds(30)))

        fixture.analyzer.succeed(0)
        await waitUntil { fixture.storage.inputs.count == 1 }
        XCTAssertTrue(fixture.model.isSaving)
        XCTAssertFalse(fixture.model.isAnalyzing)
        XCTAssertEqual(fixture.storage.inputs[0].title, "User title")
        XCTAssertEqual(fixture.storage.inputs[0].sentences, Fixture.analysis.sentences)
        fixture.storage.succeed(0, id: 42)
        await task.value

        XCTAssertFalse(fixture.model.isLoading)
        XCTAssertEqual(fixture.model.completion?.savedID, 42)
        XCTAssertEqual(fixture.model.consumeCompletion()?.title, "User title")
        XCTAssertNil(fixture.model.consumeCompletion())
        await fixture.model.start(content: content, title: title)
        await fixture.model.retrySaving()
        fixture.model.resumeEditing()
        XCTAssertFalse(fixture.model.canStartAnalysis)
        XCTAssertFalse(fixture.model.canEdit)
        XCTAssertEqual(fixture.analyzer.inputs.count, 1)
        XCTAssertEqual(fixture.storage.inputs.count, 1)
    }

    func test_emptyTitleUsesAnalyzedTitle() async {
        let fixture = Fixture()
        defer { fixture.finishPending() }
        let task = fixture.start(title: "")
        await waitUntil { fixture.analyzer.inputs.count == 1 }
        fixture.analyzer.succeed(0)
        await waitUntil { fixture.storage.inputs.count == 1 }
        fixture.storage.succeed(0)
        await task.value
        XCTAssertEqual(fixture.storage.inputs[0].title, "Analyzed title")
        XCTAssertEqual(fixture.model.consumeCompletion()?.title, "Analyzed title")
    }

    func test_emptyAndRateRejectedRequestsDoNotStartAnalysisOrTimer() async {
        let fixture = Fixture()
        defer { fixture.finishPending() }
        await fixture.model.start(content: " \n\t ", title: "")
        XCTAssertTrue(fixture.limiter.dates.isEmpty)
        XCTAssertTrue(fixture.analyzer.inputs.isEmpty)
        XCTAssertTrue(fixture.clock.deadlines.isEmpty)

        fixture.limiter.allowed = false
        await fixture.model.start(content: "Hello", title: "")
        XCTAssertEqual(fixture.limiter.dates, [fixture.clock.date])
        XCTAssertTrue(fixture.analyzer.inputs.isEmpty)
        XCTAssertTrue(fixture.clock.deadlines.isEmpty)
        XCTAssertFalse(fixture.model.isLoading)
        XCTAssertNotNil(fixture.model.errorMessage)
        XCTAssertTrue(fixture.model.canStartAnalysis)
    }

    func test_duplicateStartDuringAnalysisDoesNotChargeOrCreateTimer() async {
        let fixture = Fixture()
        defer { fixture.finishPending() }
        let task = fixture.start()
        await waitUntil { fixture.analyzer.inputs.count == 1 && fixture.clock.deadlines.count == 1 }
        await fixture.model.start(content: "Duplicate", title: "Other")
        await fixture.model.retrySaving()
        fixture.model.resumeEditing()
        XCTAssertEqual(fixture.analyzer.inputs.count, 1)
        XCTAssertEqual(fixture.limiter.dates.count, 1)
        XCTAssertEqual(fixture.clock.deadlines.count, 1)
        XCTAssertTrue(fixture.model.isAnalyzing)
        fixture.model.cancel()
        fixture.analyzer.succeed(0)
        await task.value
        XCTAssertTrue(fixture.storage.inputs.isEmpty)
    }

    func test_typedAnalysisFailuresAreDisplayedWithoutSaving() async {
        let failures: [AIError] = [.authentication, .rateLimited, .transient, .invalidInput, .responseContract, .unknown]
        for failure in failures {
            let fixture = Fixture()
            let task = fixture.start()
            await waitUntil { fixture.analyzer.inputs.count == 1 }
            fixture.analyzer.fail(0, error: failure)
            await task.value
            XCTAssertEqual(fixture.model.errorMessage, failure.localizedDescription)
            XCTAssertTrue(fixture.storage.inputs.isEmpty)
            XCTAssertFalse(fixture.model.isLoading)
            XCTAssertTrue(fixture.model.canStartAnalysis)
            fixture.finishPending()
        }
    }

    func test_analysisCancellationIsSilentAndDoesNotSave() async {
        let fixture = Fixture()
        defer { fixture.finishPending() }
        let task = fixture.start()
        await waitUntil { fixture.analyzer.inputs.count == 1 }
        fixture.analyzer.fail(0, error: AIError.cancelled)
        await task.value
        XCTAssertNil(fixture.model.errorMessage)
        XCTAssertNil(fixture.model.completion)
        XCTAssertFalse(fixture.model.isLoading)
        XCTAssertTrue(fixture.storage.inputs.isEmpty)
    }

    func test_cancelBeforeAnalysisReturnsDiscardsLateSuccess() async {
        let fixture = Fixture()
        defer { fixture.finishPending() }
        let task = fixture.start()
        await waitUntil { fixture.analyzer.inputs.count == 1 }
        fixture.model.cancel()
        XCTAssertFalse(fixture.model.isLoading)
        XCTAssertTrue(fixture.model.canStartAnalysis)
        fixture.analyzer.succeed(0)
        await task.value
        XCTAssertTrue(fixture.storage.inputs.isEmpty)
        XCTAssertNil(fixture.model.errorMessage)
        XCTAssertNil(fixture.model.completion)
    }

    func test_responseAtExactDeadlineTimesOutEvenBeforeTimerResumes() async {
        let fixture = Fixture()
        defer { fixture.finishPending() }
        let task = fixture.start()
        await waitUntil { fixture.analyzer.inputs.count == 1 && fixture.clock.deadlines.count == 1 }
        fixture.clock.advance(seconds: 30)
        fixture.analyzer.succeed(0)
        await task.value
        XCTAssertTrue(fixture.storage.inputs.isEmpty)
        XCTAssertNotNil(fixture.model.errorMessage)
        XCTAssertFalse(fixture.model.isLoading)
        XCTAssertTrue(fixture.model.canStartAnalysis)
    }

    func test_timeoutThenNewRequestIgnoresLateOldAnalysis() async {
        let fixture = Fixture()
        defer { fixture.finishPending() }
        let first = fixture.start(content: "A")
        await waitUntil { fixture.analyzer.inputs.count == 1 && fixture.clock.deadlines.count == 1 }
        fixture.clock.advance(seconds: 30)
        fixture.clock.wake(0)
        await waitUntil { !fixture.model.isAnalyzing }
        XCTAssertNotNil(fixture.model.errorMessage)

        let second = fixture.start(content: "B", title: "B title")
        await waitUntil { fixture.analyzer.inputs.count == 2 && fixture.clock.deadlines.count == 2 }
        XCTAssertEqual(fixture.clock.deadlines[1], fixture.clock.origin.advanced(by: .seconds(60)))
        fixture.analyzer.succeed(0)
        await first.value
        XCTAssertTrue(fixture.model.isAnalyzing)
        XCTAssertNil(fixture.model.errorMessage)
        XCTAssertTrue(fixture.storage.inputs.isEmpty)
        fixture.analyzer.succeed(1)
        await waitUntil { fixture.storage.inputs.count == 1 }
        fixture.storage.succeed(0)
        await second.value
        XCTAssertEqual(fixture.model.consumeCompletion()?.title, "B title")
    }

    func test_cancelledOldTimerCannotTimeoutNewRequest() async {
        let fixture = Fixture()
        defer { fixture.finishPending() }
        let first = fixture.start(content: "A")
        await waitUntil { fixture.analyzer.inputs.count == 1 && fixture.clock.deadlines.count == 1 }
        fixture.model.cancel()
        fixture.clock.advance(seconds: 10)
        let second = fixture.start(content: "B")
        await waitUntil { fixture.analyzer.inputs.count == 2 && fixture.clock.deadlines.count == 2 }
        fixture.clock.advance(seconds: 20)
        fixture.clock.wake(0)
        await waitUntil { fixture.clock.returnedSleeps.contains(0) }
        fixture.analyzer.succeed(0)
        await first.value
        XCTAssertTrue(fixture.model.isAnalyzing)
        XCTAssertNil(fixture.model.errorMessage)
        XCTAssertTrue(fixture.storage.inputs.isEmpty)
        fixture.model.cancel()
        fixture.analyzer.succeed(1)
        await second.value
    }

    func test_analysisDeadlineDoesNotTimeoutPendingStorage() async {
        let fixture = Fixture()
        defer { fixture.finishPending() }
        let task = fixture.start()
        await waitUntil { fixture.analyzer.inputs.count == 1 && fixture.clock.deadlines.count == 1 }
        fixture.clock.advance(seconds: 29)
        fixture.analyzer.succeed(0)
        await waitUntil { fixture.storage.inputs.count == 1 }
        fixture.clock.advance(seconds: 100)
        fixture.clock.wake(0)
        await waitUntil { fixture.clock.returnedSleeps.contains(0) }
        XCTAssertTrue(fixture.model.isSaving)
        XCTAssertNil(fixture.model.errorMessage)
        fixture.storage.succeed(0)
        await task.value
        XCTAssertNotNil(fixture.model.consumeCompletion())
    }

    func test_cancelPendingStorageBlocksNewWorkAndReconcilesLateCommit() async {
        let fixture = Fixture()
        defer { fixture.finishPending() }
        let task = fixture.start()
        await waitUntil { fixture.analyzer.inputs.count == 1 }
        fixture.analyzer.succeed(0)
        await waitUntil { fixture.storage.inputs.count == 1 }
        fixture.model.cancel()
        XCTAssertTrue(fixture.model.isSaving)
        XCTAssertFalse(fixture.model.canEdit)
        XCTAssertFalse(fixture.model.canStartAnalysis)
        XCTAssertFalse(fixture.model.canRetrySaving)
        await fixture.model.start(content: "Duplicate", title: "")
        await fixture.model.retrySaving()
        fixture.model.resumeEditing()
        XCTAssertTrue(fixture.model.isSaving)
        XCTAssertEqual(fixture.analyzer.inputs.count, 1)
        XCTAssertEqual(fixture.storage.inputs.count, 1)
        fixture.storage.succeed(0)
        await task.value
        XCTAssertEqual(fixture.storage.wasCancelledAfterResume, [false])
        XCTAssertFalse(fixture.model.isSaving)
        XCTAssertNil(fixture.model.completion)
        XCTAssertNil(fixture.model.errorMessage)
        await fixture.model.start(content: "Still duplicate", title: "")
        await fixture.model.retrySaving()
        fixture.model.resumeEditing()
        XCTAssertFalse(fixture.model.canStartAnalysis)
        XCTAssertFalse(fixture.model.canEdit)
        XCTAssertEqual(fixture.storage.inputs.count, 1)
    }

    func test_failedStorageRetainsDraftAndRetryDoesNotAnalyzeOrChargeAgain() async {
        let fixture = Fixture()
        defer { fixture.finishPending() }
        let task = fixture.start(title: "Frozen title")
        await waitUntil { fixture.analyzer.inputs.count == 1 && fixture.clock.deadlines.count == 1 }
        fixture.analyzer.succeed(0)
        await waitUntil { fixture.storage.inputs.count == 1 }
        fixture.storage.fail(0, error: StorageFailure.rollback)
        await task.value
        XCTAssertTrue(fixture.model.canRetrySaving)
        XCTAssertFalse(fixture.model.canStartAnalysis)
        XCTAssertNotNil(fixture.model.errorMessage)
        await fixture.model.start(content: "Unwanted analysis", title: "")
        let retry = Task { await fixture.model.retrySaving() }
        await waitUntil { fixture.storage.inputs.count == 2 }
        await fixture.model.retrySaving()
        XCTAssertEqual(fixture.storage.inputs[0], fixture.storage.inputs[1])
        XCTAssertEqual(fixture.analyzer.inputs.count, 1)
        XCTAssertEqual(fixture.limiter.dates.count, 1)
        XCTAssertEqual(fixture.clock.deadlines.count, 1)
        fixture.storage.succeed(1, id: 84)
        await retry.value
        XCTAssertEqual(fixture.model.consumeCompletion()?.savedID, 84)
        XCTAssertFalse(fixture.model.canRetrySaving)
    }

    func test_cancelPendingStorageThenRollbackAllowsSilentDraftRetry() async {
        let fixture = Fixture()
        defer { fixture.finishPending() }
        let task = fixture.start()
        await waitUntil { fixture.analyzer.inputs.count == 1 }
        fixture.analyzer.succeed(0)
        await waitUntil { fixture.storage.inputs.count == 1 }
        fixture.model.cancel()
        fixture.storage.fail(0, error: StorageFailure.rollback)
        await task.value
        XCTAssertNil(fixture.model.errorMessage)
        XCTAssertTrue(fixture.model.canRetrySaving)
        XCTAssertEqual(fixture.storage.wasCancelledAfterResume, [false])
        let retry = Task { await fixture.model.retrySaving() }
        await waitUntil { fixture.storage.inputs.count == 2 }
        fixture.storage.succeed(1)
        await retry.value
        XCTAssertNotNil(fixture.model.consumeCompletion())
        XCTAssertEqual(fixture.analyzer.inputs.count, 1)
        XCTAssertEqual(fixture.limiter.dates.count, 1)
    }

    func test_resumeEditingExplicitlyDiscardsOnlyConfirmedFailedDraft() async {
        let fixture = Fixture()
        defer { fixture.finishPending() }
        let first = fixture.start()
        await waitUntil { fixture.analyzer.inputs.count == 1 }
        fixture.analyzer.succeed(0)
        await waitUntil { fixture.storage.inputs.count == 1 }
        fixture.storage.fail(0, error: StorageFailure.rollback)
        await first.value
        fixture.model.resumeEditing()
        XCTAssertFalse(fixture.model.canRetrySaving)
        XCTAssertTrue(fixture.model.canStartAnalysis)
        XCTAssertTrue(fixture.model.canEdit)
        XCTAssertNil(fixture.model.errorMessage)
        let second = fixture.start(content: "Edited request")
        await waitUntil { fixture.analyzer.inputs.count == 2 }
        XCTAssertEqual(fixture.analyzer.inputs[1], "Edited request")
        fixture.model.cancel()
        fixture.analyzer.succeed(1)
        await second.value
    }

    func test_unknownStorageOutcomePreventsRetryEditingAndDuplicateAnalysis() async {
        for missingID in [true, false] {
            let fixture = Fixture()
            let task = fixture.start()
            await waitUntil { fixture.analyzer.inputs.count == 1 }
            fixture.analyzer.succeed(0)
            await waitUntil { fixture.storage.inputs.count == 1 }
            if missingID {
                fixture.storage.succeed(0, id: nil)
            } else {
                fixture.storage.fail(0, error: CancellationError())
            }
            await task.value
            XCTAssertFalse(fixture.model.isSaving)
            XCTAssertFalse(fixture.model.canRetrySaving)
            XCTAssertFalse(fixture.model.canEdit)
            XCTAssertFalse(fixture.model.canStartAnalysis)
            XCTAssertNil(fixture.model.completion)
            fixture.model.cancel()
            fixture.model.resumeEditing()
            await fixture.model.retrySaving()
            await fixture.model.start(content: "Duplicate", title: "")
            XCTAssertFalse(fixture.model.canStartAnalysis)
            XCTAssertEqual(fixture.analyzer.inputs.count, 1)
            XCTAssertEqual(fixture.storage.inputs.count, 1)
            fixture.finishPending()
        }
    }

    func test_cancelAfterSuccessSuppressesUnconsumedNavigation() async {
        let fixture = Fixture()
        defer { fixture.finishPending() }
        let task = fixture.start()
        await waitUntil { fixture.analyzer.inputs.count == 1 }
        fixture.analyzer.succeed(0)
        await waitUntil { fixture.storage.inputs.count == 1 }
        fixture.storage.succeed(0)
        await task.value
        XCTAssertNotNil(fixture.model.completion)
        fixture.model.cancel()
        XCTAssertNil(fixture.model.consumeCompletion())
        XCTAssertFalse(fixture.model.canStartAnalysis)
    }

    func test_cancellingCallerTaskLeavesStorageRunningAndSuppressesCompletion() async {
        let fixture = Fixture()
        defer { fixture.finishPending() }
        let task = fixture.start()
        await waitUntil { fixture.analyzer.inputs.count == 1 }
        fixture.analyzer.succeed(0)
        await waitUntil { fixture.storage.inputs.count == 1 }
        task.cancel()
        await waitUntil { !fixture.model.isLoading }
        XCTAssertTrue(fixture.model.isSaving)
        XCTAssertFalse(fixture.model.canStartAnalysis)
        fixture.storage.succeed(0)
        await task.value
        XCTAssertEqual(fixture.storage.wasCancelledAfterResume, [false])
        XCTAssertNil(fixture.model.consumeCompletion())
        XCTAssertFalse(fixture.model.canStartAnalysis)
    }

    func test_storageResponseThenImmediateCallerCancellationSuppressesCompletion() async {
        await assertStorageCompletionCancelledInSameActorTurn(responseFirst: true)
    }

    func test_callerCancellationThenImmediateStorageResponseSuppressesCompletion() async {
        await assertStorageCompletionCancelledInSameActorTurn(responseFirst: false)
    }

    func test_analysisResponseThenImmediateCallerCancellationDoesNotStartStorage() async {
        let fixture = Fixture()
        defer { fixture.finishPending() }
        // A regression must fail the assertion rather than suspend forever in an unexpected save.
        fixture.storage.completesImmediately = true
        let task = fixture.start()
        await waitUntil { fixture.analyzer.inputs.count == 1 }
        fixture.analyzer.succeed(0)
        task.cancel()
        await task.value
        XCTAssertTrue(fixture.storage.inputs.isEmpty)
        XCTAssertNil(fixture.model.completion)
        XCTAssertNil(fixture.model.consumeCompletion())
    }

    private func assertStorageCompletionCancelledInSameActorTurn(
        responseFirst: Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        let fixture = Fixture()
        defer { fixture.finishPending() }
        let task = fixture.start()
        await waitUntil { fixture.analyzer.inputs.count == 1 }
        fixture.analyzer.succeed(0)
        await waitUntil { fixture.storage.inputs.count == 1 }
        // No suspension between the response and cancellation: the queued MainActor
        // cancellation handler cannot be relied on to invalidate completion in time.
        if responseFirst {
            fixture.storage.succeed(0)
            task.cancel()
        } else {
            task.cancel()
            fixture.storage.succeed(0)
        }
        await task.value
        XCTAssertNil(fixture.model.completion, file: file, line: line)
        XCTAssertNil(fixture.model.consumeCompletion(), file: file, line: line)
        XCTAssertEqual(fixture.storage.wasCancelledAfterResume, [false], file: file, line: line)
        await fixture.model.start(content: "Duplicate", title: "")
        await fixture.model.retrySaving()
        XCTAssertFalse(fixture.model.canStartAnalysis, file: file, line: line)
        XCTAssertEqual(fixture.analyzer.inputs.count, 1, file: file, line: line)
        XCTAssertEqual(fixture.storage.inputs.count, 1, file: file, line: line)
    }

    func test_completionUsesTitleReturnedByPersistence() async {
        let fixture = Fixture()
        defer { fixture.finishPending() }
        let task = fixture.start(title: "Requested title")
        await waitUntil { fixture.analyzer.inputs.count == 1 }
        fixture.analyzer.succeed(0)
        await waitUntil { fixture.storage.inputs.count == 1 }
        XCTAssertEqual(fixture.storage.inputs[0].title, "Requested title")
        fixture.storage.succeed(0, title: "Persisted title")
        await task.value
        XCTAssertEqual(fixture.model.consumeCompletion()?.title, "Persisted title")
    }

    func test_pendingSaveRetainsModelAfterScreenReleasesItsReference() async {
        let analyzer = ControlledAnalyzer()
        let storage = ControlledStorage()
        let clock = ScriptConfirmTestClock()
        var model: ScriptConfirmViewModel? = ScriptConfirmViewModel(
            analyzer: analyzer, scriptService: storage, rateLimiter: ControlledRateLimiter(), clock: clock
        )
        weak let retainedModel = model
        defer {
            retainedModel?.cancel()
            analyzer.finishPending()
            storage.finishPending()
            clock.finishPending()
        }
        let task = Task { [current = model!] in await current.start(content: "Hello.", title: "Title") }
        await waitUntil { analyzer.inputs.count == 1 }
        analyzer.succeed(0)
        await waitUntil { storage.inputs.count == 1 }
        model?.cancel()
        model = nil
        XCTAssertNotNil(retainedModel)
        XCTAssertTrue(retainedModel?.isSaving == true)
        XCTAssertFalse(retainedModel?.canStartAnalysis == true)
        storage.succeed(0)
        await task.value
        XCTAssertEqual(storage.wasCancelledAfterResume, [false])
        XCTAssertEqual(storage.inputs.count, 1)
        XCTAssertNil(retainedModel?.completion)
    }

    private func waitUntil(
        file: StaticString = #filePath,
        line: UInt = #line,
        _ predicate: @escaping @MainActor () -> Bool
    ) async {
        let waiter = ConditionWaiter(predicate: predicate)
        waiter.observe()
        await fulfillment(of: [waiter.expectation], timeout: 2)
        XCTAssertTrue(predicate(), file: file, line: line)
    }
}

@MainActor
private final class ConditionWaiter {
    let expectation = XCTestExpectation(description: "Controlled workflow reached expected state")
    private let predicate: @MainActor () -> Bool

    init(predicate: @escaping @MainActor () -> Bool) {
        self.predicate = predicate
    }

    func observe() {
        withObservationTracking {
            if predicate() { expectation.fulfill() }
        } onChange: {
            Task { @MainActor in self.observe() }
        }
    }
}

@MainActor
private final class Fixture {
    static let analysis = ScriptData(title: "Analyzed title", sentences: [
        SentenceData(orderIndex: 0, englishText: "Hello.", koreanText: "안녕.", chunks: [
            ChunkData(orderIndex: 0, englishText: "Hello.", koreanText: "안녕.")
        ])
    ])
    let analyzer = ControlledAnalyzer()
    let storage = ControlledStorage()
    let limiter = ControlledRateLimiter()
    let clock = ScriptConfirmTestClock()
    let model: ScriptConfirmViewModel

    init() {
        model = ScriptConfirmViewModel(analyzer: analyzer, scriptService: storage, rateLimiter: limiter, clock: clock)
    }

    func start(content: String = "Hello.", title: String = "Title") -> Task<Void, Never> {
        Task { await model.start(content: content, title: title) }
    }

    func finishPending() {
        model.cancel()
        analyzer.finishPending()
        storage.finishPending()
        clock.finishPending()
    }
}

@MainActor @Observable
private final class ControlledAnalyzer: ScriptAnalyzing {
    private(set) var inputs: [String] = []
    @ObservationIgnored private var pending: [Int: CheckedContinuation<ScriptData, Error>] = [:]

    func analyzeScript(_ content: String) async throws -> ScriptData {
        let index = inputs.count
        return try await withCheckedThrowingContinuation { continuation in
            pending[index] = continuation
            inputs.append(content)
        }
    }

    func succeed(_ index: Int) {
        pending.removeValue(forKey: index)?.resume(returning: Fixture.analysis)
    }

    func fail(_ index: Int, error: Error) {
        pending.removeValue(forKey: index)?.resume(throwing: error)
    }

    func finishPending() {
        for index in Array(pending.keys) { fail(index, error: AIError.cancelled) }
    }
}

@MainActor
private final class ControlledRateLimiter: AnalysisRateLimiting {
    var allowed = true
    private(set) var dates: [Date] = []

    func canCall(at now: Date) -> Bool {
        dates.append(now)
        return allowed
    }
}


private enum StorageFailure: Error {
    case rollback
}

@MainActor @Observable
private final class ControlledStorage: ScriptManagementServiceProtocol {
    var completesImmediately = false
    private(set) var inputs: [ScriptData] = []
    private(set) var wasCancelledAfterResume: [Bool] = []
    @ObservationIgnored private var pending: [Int: CheckedContinuation<Script, Error>] = [:]

    func createScript(scriptData: ScriptData) async throws -> Script {
        let index = inputs.count
        defer { wasCancelledAfterResume.append(Task.isCancelled) }
        if completesImmediately {
            inputs.append(scriptData)
            let date = Date(timeIntervalSince1970: 0)
            return Script(id: 42, title: scriptData.title, createdAt: date, lastViewedAt: date)
        }
        return try await withCheckedThrowingContinuation { continuation in
            pending[index] = continuation
            inputs.append(scriptData)
        }
    }

    func succeed(_ index: Int, id: Int64? = 42, title: String? = nil) {
        let date = Date(timeIntervalSince1970: 0)
        let result = Script(id: id, title: title ?? inputs[index].title, createdAt: date, lastViewedAt: date)
        pending.removeValue(forKey: index)?.resume(returning: result)
    }

    func fail(_ index: Int, error: Error) {
        pending.removeValue(forKey: index)?.resume(throwing: error)
    }

    func finishPending() {
        for index in Array(pending.keys) { fail(index, error: StorageFailure.rollback) }
    }

    func fetchAllScripts() async throws -> [Script] { fatalError("Unexpected read") }
    func deleteScript(id: Int64) async throws { fatalError("Unexpected delete") }
    func fetchScript(id: Int64) async throws -> Script? { fatalError("Unexpected read") }
    func fetchScriptWithSentences(id: Int64) async throws -> (script: Script, sentences: [Sentence]) {
        fatalError("Unexpected read")
    }
    func fetchScriptWithSentencesAndChunks(id: Int64) async throws -> (script: Script, sentences: [(sentence: Sentence, chunks: [Chunk])]) {
        fatalError("Unexpected read")
    }
    func updateLastViewedAt(forScriptId scriptId: Int64) async throws { fatalError("Unexpected update") }
    func updateScriptTitle(scriptId: Int64, newTitle: String) async throws { fatalError("Unexpected update") }
    func fetchAllFeedbackSummaries() async throws -> [FeedbackSummary] { fatalError("Unexpected read") }
    func fetchFeedbackSummaries(forScriptId scriptId: Int64) async throws -> [FeedbackSummary] { fatalError("Unexpected read") }
    func fetchFeedbackDetails(forFeedbackSummaryId feedbackSummaryId: Int64) async throws -> [FeedbackDetail] {
        fatalError("Unexpected read")
    }
    func createFeedbackSummary(
        scriptId: Int64,
        accuracy: Double,
        missingWordCount: Int,
        addedWordCount: Int,
        replacedWordCount: Int,
        practiceDuration: Double,
        feedbackDetailsData: [(wordDiff: WordDiff, originalText: String?, sentenceIndex: Int, wordIndex: Int)]
    ) async throws -> FeedbackSummary { fatalError("Unexpected feedback write") }
}
