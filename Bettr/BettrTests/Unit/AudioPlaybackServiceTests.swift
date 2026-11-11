import AVFoundation
import BettrAI
import XCTest
@testable import Bettr

/// 기기 없이 합성기 이벤트를 직접 공급하는 Fake입니다. 실제 합성기와 달리 중단된 발화의
/// 이벤트도 테스트가 원하는 시점(늦게)에 보낼 수 있습니다.
@MainActor
final class FakeSpeechSynthesizer: SpeechSynthesizing {
    var onEvent: (@MainActor (SpeechEvent) -> Void)?
    private(set) var spoken: [AVSpeechUtterance] = []
    private(set) var stopCount = 0
    private(set) var pauseCount = 0
    private(set) var continueCount = 0
    private(set) var isSpeaking = false

    func speak(_ utterance: AVSpeechUtterance) {
        spoken.append(utterance)
        isSpeaking = true
    }

    func stopSpeaking() {
        stopCount += 1
        isSpeaking = false
    }

    func pauseSpeaking() { pauseCount += 1 }
    func continueSpeaking() { continueCount += 1 }

    func send(_ kind: SpeechEvent.Kind, to utterance: AVSpeechUtterance) {
        onEvent?(SpeechEvent(utteranceID: ObjectIdentifier(utterance), kind: kind))
    }

    func finish(_ utterance: AVSpeechUtterance) {
        isSpeaking = false
        send(.didFinish, to: utterance)
    }
}

@MainActor
final class AudioPlaybackServiceTests: XCTestCase {
    private var synthesizer: FakeSpeechSynthesizer!
    private var service: AudioPlaybackService!

    override func setUp() {
        super.setUp()
        synthesizer = FakeSpeechSynthesizer()
        service = AudioPlaybackService(synthesizer: synthesizer, interSentenceDelay: .milliseconds(5))
    }

    // MARK: 전체 재생

    func test_playAll_whenSentencesFinish_thenAdvancesInOrderAndEndsStopped() async {
        service.playAll(sentences: [sentence(1, "Second."), sentence(0, "First.")])
        XCTAssertEqual(service.currentPlaybackMode, .multi)
        XCTAssertEqual(service.currentMultiSentenceIndex, 0)
        XCTAssertEqual(synthesizer.spoken.map(\.speechString), ["First."])

        synthesizer.send(.didStart, to: synthesizer.spoken[0])
        synthesizer.send(.willSpeak(range: NSRange(location: 0, length: 5)), to: synthesizer.spoken[0])
        XCTAssertTrue(service.isPlaybackActive)
        XCTAssertEqual(service.currentSpokenRange, NSRange(location: 0, length: 5))

        synthesizer.finish(synthesizer.spoken[0])
        await waitUntil { self.synthesizer.spoken.count == 2 }
        XCTAssertEqual(service.currentMultiSentenceIndex, 1)
        XCTAssertNil(service.currentSpokenRange)

        synthesizer.finish(synthesizer.spoken[1])
        assertStopped()
    }

    func test_playAll_whenStoppedDuringInterSentenceDelay_thenNextSentenceNeverStarts() async {
        service.playAll(sentences: [sentence(0, "First."), sentence(1, "Second.")])
        synthesizer.finish(synthesizer.spoken[0])

        service.stop()
        try? await Task.sleep(for: .milliseconds(40))

        XCTAssertEqual(synthesizer.spoken.count, 1)
        assertStopped()
    }

    func test_playAll_whenNewSingleStartsDuringInterSentenceDelay_thenQueueIsDiscarded() async {
        service.playAll(sentences: [sentence(0, "First."), sentence(1, "Second.")])
        synthesizer.finish(synthesizer.spoken[0])

        service.play(text: "Chunk", id: .sentence(7))
        try? await Task.sleep(for: .milliseconds(40))

        XCTAssertEqual(synthesizer.spoken.map(\.speechString), ["First.", "Chunk"])
        XCTAssertEqual(service.currentPlaybackMode, .single)
        XCTAssertEqual(service.currentPlaybackID, .sentence(7))
        XCTAssertNil(service.currentMultiSentenceIndex)
    }

    // MARK: 일시정지 / 재개

    func test_pause_thenResume_thenKeepsTargetAndClearsPaused() {
        service.play(text: "Hello", id: .sentence(0))
        synthesizer.send(.didStart, to: synthesizer.spoken[0])

        service.pause()
        XCTAssertTrue(service.isPaused)
        XCTAssertEqual(synthesizer.pauseCount, 1)
        XCTAssertEqual(service.currentPlaybackID, .sentence(0))

        service.resume()
        XCTAssertFalse(service.isPaused)
        XCTAssertEqual(synthesizer.continueCount, 1)
        XCTAssertEqual(service.currentPlaybackID, .sentence(0))
    }

    func test_pause_whenStopped_thenIgnored() {
        service.pause()
        XCTAssertFalse(service.isPaused)
        XCTAssertEqual(synthesizer.pauseCount, 0)
        service.resume()
        XCTAssertEqual(synthesizer.continueCount, 0)
    }

    func test_pause_duringInterSentenceDelay_thenResumeStartsNextSentence() async {
        service.playAll(sentences: [sentence(0, "First."), sentence(1, "Second.")])
        synthesizer.finish(synthesizer.spoken[0])

        service.pause()
        XCTAssertTrue(service.isPaused)
        try? await Task.sleep(for: .milliseconds(40))
        XCTAssertEqual(synthesizer.spoken.count, 1, "일시정지 중에는 다음 문장을 시작하지 않는다")

        service.resume()
        XCTAssertFalse(service.isPaused)
        XCTAssertEqual(synthesizer.spoken.map(\.speechString), ["First.", "Second."])
        XCTAssertEqual(service.currentMultiSentenceIndex, 1)
    }

    func test_stop_whenPaused_thenClearsPaused() {
        service.playAll(sentences: [sentence(0, "First.")])
        service.pause()
        service.stop()
        assertStopped()
    }

    func test_play_whenPaused_thenNewPlaybackIsNotPaused() {
        service.play(text: "A", id: .sentence(0))
        service.pause()
        service.play(text: "B", id: .sentence(1))
        XCTAssertFalse(service.isPaused)
        XCTAssertEqual(service.currentPlaybackID, .sentence(1))
    }

    // MARK: 대상 ID

    func test_play_whenSameTextHasDifferentTargets_thenFollowsLatestTargetID() {
        let first = ChunkIdentifier(sentenceIndex: 0, chunkIndex: 0)
        let second = ChunkIdentifier(sentenceIndex: 1, chunkIndex: 0)

        service.play(text: "Same words", id: .chunk(first))
        service.play(text: "Same words", id: .chunk(second))

        XCTAssertEqual(service.currentPlaybackID, .chunk(second))
        XCTAssertEqual(service.currentPlaybackMode, .single)
    }

    // MARK: 늦은 이벤트

    func test_lateFinishOfPreviousSingle_thenDoesNotChangeNewTarget() {
        service.play(text: "Old", id: .sentence(0))
        let old = synthesizer.spoken[0]
        service.play(text: "New", id: .sentence(1))
        let new = synthesizer.spoken[1]
        synthesizer.send(.didStart, to: new)
        synthesizer.send(.willSpeak(range: NSRange(location: 0, length: 2)), to: new)

        synthesizer.send(.didCancel, to: old)
        synthesizer.send(.didFinish, to: old)
        synthesizer.send(.willSpeak(range: NSRange(location: 0, length: 3)), to: old)
        synthesizer.send(.didStart, to: old)

        XCTAssertEqual(service.currentPlaybackID, .sentence(1))
        XCTAssertEqual(service.currentPlaybackMode, .single)
        XCTAssertTrue(service.isPlaybackActive)
        XCTAssertEqual(service.currentSpokenRange, NSRange(location: 0, length: 2))
    }

    func test_lateEventsAfterStop_thenStayStopped() {
        service.play(text: "Old", id: .sentence(0))
        let old = synthesizer.spoken[0]
        service.stop()

        synthesizer.send(.didStart, to: old)
        synthesizer.send(.didContinue, to: old)

        assertStopped()
    }

    func test_lateCancelOfPreviousWholePlayback_thenDoesNotStopNewPlayAll() {
        service.playAll(sentences: [sentence(0, "A")])
        let old = synthesizer.spoken[0]
        service.playAll(sentences: [sentence(0, "B"), sentence(1, "C")])

        synthesizer.send(.didCancel, to: old)
        synthesizer.send(.didFinish, to: old)

        XCTAssertEqual(service.currentPlaybackMode, .multi)
        XCTAssertEqual(service.currentMultiSentenceIndex, 0)
    }

    func test_cancelOfCurrentUtterance_thenResetsState() {
        service.play(text: "A", id: .sentence(0))
        synthesizer.send(.didCancel, to: synthesizer.spoken[0])
        assertStopped()
    }

    // MARK: Helpers

    private func assertStopped(file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(service.currentPlaybackMode, .stopped, file: file, line: line)
        XCTAssertFalse(service.isPlaybackActive, file: file, line: line)
        XCTAssertFalse(service.isPaused, file: file, line: line)
        XCTAssertNil(service.currentPlaybackID, file: file, line: line)
        XCTAssertNil(service.currentMultiSentenceIndex, file: file, line: line)
        XCTAssertNil(service.currentSpokenRange, file: file, line: line)
    }

    private func sentence(_ index: Int, _ text: String) -> SentenceData {
        SentenceData(orderIndex: index, englishText: text, koreanText: "", chunks: [])
    }

    private func waitUntil(_ condition: () -> Bool, file: StaticString = #filePath, line: UInt = #line) async {
        for _ in 0..<200 {
            if condition() { return }
            try? await Task.sleep(for: .milliseconds(5))
        }
        XCTFail("조건이 시간 안에 충족되지 않았다", file: file, line: line)
    }
}
