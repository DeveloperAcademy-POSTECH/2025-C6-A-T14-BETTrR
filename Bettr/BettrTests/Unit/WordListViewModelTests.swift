import XCTest
@testable import Bettr

@MainActor
final class WordListViewModelTests: XCTestCase {
    func test_load_whenCachedWordsExist_thenSkipsExtraction() async {
        let fake = FakeWordService()
        fake.words = Self.words
        let model = WordListViewModel(scriptId: 1, wordExtractionService: fake)
        await model.loadWords()
        XCTAssertEqual(model.words.map(\.lemma), ["challenge"])
        XCTAssertEqual(fake.extractions, 0)
        XCTAssertFalse(model.isLoading)
        XCTAssertNil(model.errorMessage)
    }

    func test_load_whenExtractionSucceeds_thenLoadsSavedWords() async {
        let fake = FakeWordService()
        fake.extractedWords = Self.words
        let model = WordListViewModel(scriptId: 1, wordExtractionService: fake)
        await model.loadWords()
        XCTAssertEqual(model.words.map(\.lemma), ["challenge"])
        XCTAssertEqual(fake.extractions, 1)
        XCTAssertFalse(model.isLoading)
        XCTAssertNil(model.errorMessage)
    }

    func test_load_whenAIFails_thenKeepsFailureVisibleAndRetryClearsIt() async {
        let fake = FakeWordService()
        fake.failure = AIError.rateLimited
        let model = WordListViewModel(scriptId: 1, wordExtractionService: fake)
        await model.loadWords()
        XCTAssertEqual(model.errorMessage, AIError.rateLimited.errorDescription)
        XCTAssertTrue(model.words.isEmpty)
        XCTAssertFalse(model.isLoading)

        fake.failure = nil
        fake.extractedWords = Self.words
        await model.loadWords()
        XCTAssertNil(model.errorMessage)
        XCTAssertEqual(model.words.count, 1)
        XCTAssertEqual(fake.extractions, 2)
    }

    func test_load_whenDBFails_thenKeepsFailureVisibleInsteadOfEmptySuccess() async {
        let fake = FakeWordService()
        fake.failure = DatabaseFailure()
        let model = WordListViewModel(scriptId: 1, wordExtractionService: fake)
        await model.loadWords()
        XCTAssertNotNil(model.errorMessage)
        XCTAssertTrue(model.words.isEmpty)
        XCTAssertFalse(model.isLoading)
    }

    func test_load_whenDBReadFails_thenDoesNotStartAI() async {
        let fake = FakeWordService()
        fake.readFailure = DatabaseFailure()
        let model = WordListViewModel(scriptId: 1, wordExtractionService: fake)
        await model.loadWords()
        XCTAssertNotNil(model.errorMessage)
        XCTAssertEqual(fake.extractions, 0)
        XCTAssertFalse(model.isLoading)
    }

    func test_load_whenCancelled_thenDoesNotShowFailure() async {
        for failure: Error in [AIError.cancelled, CancellationError()] {
            let fake = FakeWordService()
            fake.failure = failure
            let model = WordListViewModel(scriptId: 1, wordExtractionService: fake)
            await model.loadWords()
            XCTAssertNil(model.errorMessage)
            XCTAssertTrue(model.words.isEmpty)
            XCTAssertFalse(model.isLoading)
        }
    }

    func test_load_whenCancelledDuringRead_thenDiscardsLateWords() async {
        let fake = FakeWordService()
        fake.words = Self.words
        fake.beforeFetch = { withUnsafeCurrentTask { $0?.cancel() } }
        let model = WordListViewModel(scriptId: 1, wordExtractionService: fake)
        await Task { await model.loadWords() }.value
        XCTAssertTrue(model.words.isEmpty)
        XCTAssertNil(model.errorMessage)
        XCTAssertFalse(model.isLoading)
        XCTAssertEqual(fake.extractions, 0)
    }

    func test_load_whenReturningBeforeCancelledReadFinishes_thenNewLoadSurvivesLateResult() async {
        let fake = FakeWordService()
        fake.words = Self.words
        fake.suspendFirstFetch = true
        let model = WordListViewModel(scriptId: 1, wordExtractionService: fake)
        let oldTask = Task { await model.loadWords() }
        await fake.waitUntilSuspended()
        oldTask.cancel()
        model.cancelLoading()

        await model.loadWords()
        XCTAssertEqual(model.words.count, 1)
        fake.finishFirstFetch()
        await oldTask.value
        XCTAssertEqual(model.words.count, 1)
        XCTAssertFalse(model.isLoading)
        XCTAssertNil(model.errorMessage)
    }

    private static let words = [Word(scriptId: 1, lemma: "challenge", pos: "명", meaning: "도전", orderIndex: 0)]
}

private struct DatabaseFailure: Error {}

@MainActor
private final class FakeWordService: WordExtractionServicing {
    var words: [Word] = []
    var extractedWords: [Word] = []
    var failure: Error?
    var readFailure: Error?
    var extractions = 0
    var beforeFetch: (() -> Void)?
    var suspendFirstFetch = false
    private var fetchCount = 0
    private var firstFetch: CheckedContinuation<[Word], Never>?
    private var suspended: CheckedContinuation<Void, Never>?

    func fetchWords(for scriptId: Int64) async throws -> [Word] {
        beforeFetch?()
        fetchCount += 1
        if suspendFirstFetch && fetchCount == 1 {
            return await withCheckedContinuation { continuation in
                firstFetch = continuation
                suspended?.resume()
                suspended = nil
            }
        }
        if let readFailure { throw readFailure }
        return words
    }

    func waitUntilSuspended() async {
        if firstFetch != nil { return }
        await withCheckedContinuation { suspended = $0 }
    }

    func finishFirstFetch() {
        firstFetch?.resume(returning: words)
        firstFetch = nil
    }

    func extractAndSaveWords(for scriptId: Int64) async throws {
        extractions += 1
        if let failure { throw failure }
        words = extractedWords
    }
}
