import BettrAI
import XCTest
@testable import Bettr

@MainActor
final class MemorizationPlaybackTests: XCTestCase {
    private var audio: FakeAudioPlayback!
    private var model: MemorizationViewModel!

    override func setUp() {
        super.setUp()
        audio = FakeAudioPlayback()
        model = MemorizationViewModel(
            scriptId: 1,
            scriptTitle: "Title",
            scriptService: FakeMemorizationStorage(),
            audioService: audio
        )
        model.scriptData = ScriptData(title: "Title", sentences: [
            SentenceData(orderIndex: 0, englishText: "Same words", koreanText: "", chunks: [
                ChunkData(orderIndex: 0, englishText: "Same", koreanText: "")
            ]),
            SentenceData(orderIndex: 1, englishText: "Same words", koreanText: "", chunks: [
                ChunkData(orderIndex: 0, englishText: "Same", koreanText: "")
            ])
        ])
    }

    // MARK: 전체 재생

    func test_togglePlayStop_whenIdle_thenStartsFullPlaybackInHideMode() {
        model.uiState.funcMode = .read

        model.togglePlayStop()

        XCTAssertEqual(audio.playAllCount, 1)
        XCTAssertTrue(model.isFullPlaybackActive)
        XCTAssertEqual(model.uiState.funcMode, .hide)
    }

    func test_togglePlayStop_whenFullPlaybackActive_thenStops() {
        model.togglePlayStop()
        model.togglePlayStop()

        XCTAssertEqual(audio.stopCount, 1)
        XCTAssertFalse(model.isFullPlaybackActive)
    }

    func test_serviceFinishesPlayback_thenDerivedStateFollowsWithoutSync() {
        model.togglePlayStop()
        model.togglePauseResume()
        XCTAssertTrue(model.isPlaybackPaused)

        audio.finishPlayback()

        XCTAssertFalse(model.isFullPlaybackActive)
        XCTAssertFalse(model.isPlaybackPaused)
        model.togglePlayStop()
        XCTAssertEqual(audio.playAllCount, 2, "종료 뒤 첫 탭은 정지가 아니라 새 재생이어야 한다")
    }

    func test_togglePlayStop_whenNoScriptData_thenDoesNothing() {
        model.scriptData = nil
        model.togglePlayStop()
        XCTAssertEqual(audio.playAllCount, 0)
        XCTAssertFalse(model.isFullPlaybackActive)
    }

    // MARK: 일시정지 / 재개

    func test_togglePauseResume_thenFollowsServicePausedState() {
        model.togglePlayStop()

        model.togglePauseResume()
        XCTAssertTrue(model.isPlaybackPaused)
        XCTAssertTrue(audio.isPaused)

        model.togglePauseResume()
        XCTAssertFalse(model.isPlaybackPaused)
    }

    func test_togglePauseResume_whenNotFullPlayback_thenIgnored() {
        model.togglePauseResume()
        XCTAssertFalse(audio.isPaused)

        model.uiState.funcMode = .read
        model.handleSentenceTap(sentence: model.scriptData!.sentences[0])
        model.togglePauseResume()
        XCTAssertFalse(audio.isPaused)
    }

    // MARK: 문장 / 청크 전환

    func test_sentenceTap_whenReadMode_thenPlaysSingleAndSecondTapStopsSameTarget() {
        model.uiState.funcMode = .read
        let sentence = model.scriptData!.sentences[0]

        model.handleSentenceTap(sentence: sentence)
        XCTAssertTrue(model.isSinglePlaybackActive)
        XCTAssertEqual(audio.currentPlaybackID, .sentence(0))

        model.handleSentenceTap(sentence: sentence)
        XCTAssertFalse(model.isSinglePlaybackActive)
    }

    func test_sentenceTap_whenSameTextDifferentTarget_thenSwitchesInsteadOfStopping() {
        model.uiState.funcMode = .read
        let sentences = model.scriptData!.sentences

        model.handleSentenceTap(sentence: sentences[0])
        model.handleSentenceTap(sentence: sentences[1])

        XCTAssertEqual(audio.stopCount, 0)
        XCTAssertEqual(audio.currentPlaybackID, .sentence(1))
        XCTAssertEqual(audio.playedTexts, ["Same words", "Same words"])
    }

    func test_chunkTap_whenSameTextDifferentTarget_thenSwitchesInsteadOfStopping() {
        model.uiState.funcMode = .read
        let first = ChunkIdentifier(sentenceIndex: 0, chunkIndex: 0)
        let second = ChunkIdentifier(sentenceIndex: 1, chunkIndex: 0)
        let chunk = model.scriptData!.sentences[0].chunks[0]

        model.handleChunkTap(chunk: chunk, identifier: first)
        model.handleChunkTap(chunk: chunk, identifier: second)

        XCTAssertEqual(audio.stopCount, 0)
        XCTAssertEqual(audio.currentPlaybackID, .chunk(second))

        model.handleChunkTap(chunk: chunk, identifier: second)
        XCTAssertFalse(model.isSinglePlaybackActive)
    }

    func test_tap_whenHideMode_thenTogglesHiddenWithoutPlaying() {
        model.uiState.funcMode = .hide
        model.handleSentenceTap(sentence: model.scriptData!.sentences[0])

        XCTAssertTrue(model.isSentenceHidden(0))
        XCTAssertTrue(audio.playedTexts.isEmpty)
    }

    // MARK: 전체 / 부분 재생 상호 배제

    func test_whenSinglePlaybackActive_thenFullPlaybackAndChunkModeAreBlockedWithToast() {
        model.uiState.funcMode = .read
        model.handleSentenceTap(sentence: model.scriptData!.sentences[0])

        model.togglePlayStop()
        XCTAssertEqual(audio.playAllCount, 0)
        XCTAssertEqual(model.uiState.toasterMessage, "부분 재생 중에는 전체 재생을 사용할 수 없습니다")

        model.toggleChunkMode()
        XCTAssertFalse(model.uiState.isChunkMode)
        XCTAssertEqual(model.uiState.toasterMessage, "부분 재생 중에는 모드를 변경할 수 없습니다")
        XCTAssertTrue(model.isSinglePlaybackActive)
    }

    func test_whenFullPlaybackActive_thenReadModeIsBlockedWithToast() {
        model.togglePlayStop()

        model.setFunctionMode(.read)

        XCTAssertEqual(model.uiState.funcMode, .hide)
        XCTAssertEqual(model.uiState.toasterMessage, "전체 재생 중에는 부분 재생을 사용할 수 없습니다")
        XCTAssertTrue(model.isFullPlaybackActive)
    }

    func test_toggleChunkMode_whenIdle_thenSwitchesAndClearsHidden() {
        model.handleSentenceTap(sentence: model.scriptData!.sentences[0])
        model.toggleChunkMode()

        XCTAssertTrue(model.uiState.isChunkMode)
        XCTAssertFalse(model.isSentenceHidden(0))
    }

    // MARK: 모달 / 화면 이동

    func test_presentFeedbackModal_thenStopsPlaybackAndShowsModal() {
        model.togglePlayStop()

        model.presentFeedbackModal()

        XCTAssertEqual(audio.stopCount, 1)
        XCTAssertFalse(model.isFullPlaybackActive)
        XCTAssertTrue(model.uiState.showFeedbackModal)
    }

    func test_onDisappear_thenStopsPlayback() {
        model.uiState.funcMode = .read
        model.handleSentenceTap(sentence: model.scriptData!.sentences[0])

        model.onDisappear()

        XCTAssertFalse(model.isSinglePlaybackActive)
    }

    func test_showWordList_whenPlaying_thenKeepsPlaybackAndBlockingRules() {
        model.togglePlayStop()

        model.uiState.showWordList = true

        XCTAssertEqual(audio.stopCount, 0)
        XCTAssertTrue(model.isFullPlaybackActive)
        model.setFunctionMode(.read)
        XCTAssertEqual(model.uiState.funcMode, .hide, "단어장이 열려 있어도 전체 재생 중 부분 재생은 막힌다")
    }
}
