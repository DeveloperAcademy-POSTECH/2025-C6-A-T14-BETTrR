import BettrAI
import XCTest
@testable import Bettr

@MainActor
final class MemorizationLoadingTests: XCTestCase {
    private var storage: FakeMemorizationStorage!
    private var model: MemorizationViewModel!

    override func setUp() {
        super.setUp()
        storage = FakeMemorizationStorage()
        model = MemorizationViewModel(
            scriptId: 1,
            scriptTitle: "Title",
            scriptService: storage,
            audioService: FakeAudioPlayback()
        )
    }

    func test_onAppear_whenFetchSucceeds_thenShowsScript() async {
        model.onAppear()
        await flush()
        XCTAssertTrue(model.isLoadingScript)

        storage.complete(0, title: "Title", sentenceTexts: ["Hello."])
        await flush()

        XCTAssertFalse(model.isLoadingScript)
        XCTAssertNil(model.currentError)
        XCTAssertEqual(model.scriptData?.sentences.map(\.englishText), ["Hello."])
    }

    func test_onDisappear_whenResultArrivesLate_thenIgnoresResult() async {
        model.onAppear()
        await flush()

        model.onDisappear()
        XCTAssertFalse(model.isLoadingScript)

        storage.complete(0, title: "Late", sentenceTexts: ["Late."])
        await flush()

        XCTAssertNil(model.scriptData)
        XCTAssertEqual(model.currentTitle, "Title")
        XCTAssertFalse(model.isLoadingScript)
    }

    func test_onDisappear_whenFailureArrivesLate_thenIgnoresError() async {
        model.onAppear()
        await flush()

        model.onDisappear()
        storage.fail(0, error: ScriptRepositoryError.notFound(message: "gone"))
        await flush()

        XCTAssertNil(model.currentError)
        XCTAssertEqual(model.currentTitle, "Title")
    }

    func test_reappear_whenPreviousLoadFinishesAfterNewOne_thenKeepsNewResult() async {
        model.onAppear()
        await flush()
        model.onDisappear()
        model.onAppear()
        await flush()
        XCTAssertEqual(storage.fetchCount, 2)

        storage.complete(1, title: "Title", sentenceTexts: ["New."])
        await flush()
        storage.complete(0, title: "Title", sentenceTexts: ["Old."])
        await flush()

        XCTAssertEqual(model.scriptData?.sentences.map(\.englishText), ["New."])
        XCTAssertFalse(model.isLoadingScript)
    }

    func test_retry_whenSupersedesPendingLoad_thenOldResultDoesNotOverrideNewOne() async {
        model.startLoading()
        await flush()
        model.startLoading()
        await flush()
        XCTAssertEqual(storage.fetchCount, 2)

        storage.complete(0, title: "Title", sentenceTexts: ["Old."])
        await flush()
        XCTAssertNil(model.scriptData, "대체된 요청의 결과는 반영하지 않는다")
        XCTAssertTrue(model.isLoadingScript)

        storage.complete(1, title: "Title", sentenceTexts: ["New."])
        await flush()
        XCTAssertEqual(model.scriptData?.sentences.map(\.englishText), ["New."])
        XCTAssertFalse(model.isLoadingScript)
    }

    func test_onDisappear_whenWaitingToRetry_thenStopsWithoutFetchingAgain() async {
        model.onAppear()
        await flush()
        storage.fail(0, error: ScriptRepositoryError.databaseError(message: "temporary"))
        await flush()
        XCTAssertEqual(storage.fetchCount, 1, "재시도 대기 중")

        model.onDisappear()
        await flush()

        XCTAssertEqual(storage.fetchCount, 1)
        XCTAssertNil(model.currentError)
        XCTAssertFalse(model.isLoadingScript)
    }

    func test_load_whenNotFound_thenShowsErrorWithoutRetry() async {
        model.onAppear()
        await flush()
        storage.fail(0, error: ScriptRepositoryError.notFound(message: "missing"))
        await flush()

        XCTAssertEqual(storage.fetchCount, 1)
        XCTAssertNotNil(model.currentError)
        XCTAssertFalse(model.isLoadingScript)
    }
}
