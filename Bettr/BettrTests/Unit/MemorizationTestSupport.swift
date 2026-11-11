import BettrAI
import Foundation
@testable import Bettr

/// 서비스처럼 상태를 전이하되 합성기 없이 동작하는 재생 Fake입니다.
/// `finishPlayback()`으로 서비스가 스스로 재생을 마치는 경우를 재현합니다.
@MainActor
@Observable
final class FakeAudioPlayback: AudioPlaybackServiceProtocol {
    private(set) var isPlaybackActive = false
    private(set) var isPaused = false
    private(set) var currentPlaybackMode = PlaybackMode.stopped
    private(set) var currentPlaybackID: PlaybackTargetID?
    private(set) var currentMultiSentenceIndex: Int?
    private(set) var currentSpokenRange: NSRange?

    @ObservationIgnored private(set) var stopCount = 0
    @ObservationIgnored private(set) var playedTexts: [String] = []
    @ObservationIgnored private(set) var playAllCount = 0

    func play(text: String, id: PlaybackTargetID, language: String) {
        playedTexts.append(text)
        isPaused = false
        currentPlaybackMode = .single
        currentPlaybackID = id
        currentMultiSentenceIndex = nil
        isPlaybackActive = true
    }

    func playAll(sentences: [SentenceData], language: String) {
        playAllCount += 1
        isPaused = false
        currentPlaybackMode = .multi
        currentPlaybackID = nil
        currentMultiSentenceIndex = sentences.first?.orderIndex
        isPlaybackActive = true
    }

    func stop() {
        stopCount += 1
        finishPlayback()
    }

    func pause() {
        guard currentPlaybackMode != .stopped else { return }
        isPaused = true
    }

    func resume() { isPaused = false }

    /// 서비스가 재생을 끝낸 상태(정상 종료·취소 콜백)를 재현합니다.
    func finishPlayback() {
        isPlaybackActive = false
        isPaused = false
        currentPlaybackMode = .stopped
        currentPlaybackID = nil
        currentMultiSentenceIndex = nil
        currentSpokenRange = nil
    }
}

typealias FetchedMemorizationScript = (script: Script, sentences: [(sentence: Sentence, chunks: [Chunk])])

/// 스크립트 조회를 호출마다 보류했다가 테스트가 원하는 시점에 완료(또는 실패)시킵니다.
/// 호출 Task가 취소되어도 결과를 보낼 수 있어, 늦게 도착한 결과를 ViewModel이 거르는지 검증합니다.
@MainActor
final class FakeMemorizationStorage: ScriptManagementServiceProtocol {
    private(set) var fetchCount = 0
    private var pending: [Int: CheckedContinuation<FetchedMemorizationScript, Error>] = [:]

    func fetchScriptWithSentencesAndChunks(id: Int64) async throws -> FetchedMemorizationScript {
        let index = fetchCount
        fetchCount += 1
        return try await withCheckedThrowingContinuation { pending[index] = $0 }
    }

    func complete(_ index: Int, title: String, sentenceTexts: [String]) {
        let script = Script(id: 1, title: title, createdAt: Date(timeIntervalSince1970: 0), lastViewedAt: Date(timeIntervalSince1970: 0))
        let sentences = sentenceTexts.enumerated().map { offset, text in
            (sentence: Sentence(id: Int64(offset + 1), scriptId: 1, orderIndex: offset, englishText: text, koreanText: ""), chunks: [Chunk]())
        }
        pending.removeValue(forKey: index)?.resume(returning: (script: script, sentences: sentences))
    }

    func fail(_ index: Int, error: Error) {
        pending.removeValue(forKey: index)?.resume(throwing: error)
    }

    func createScript(scriptData: ScriptData) async throws -> Script { fatalError("Unexpected write") }
    func fetchAllScripts() async throws -> [Script] { fatalError("Unexpected read") }
    func deleteScript(id: Int64) async throws { fatalError("Unexpected delete") }
    func fetchScript(id: Int64) async throws -> Script? { fatalError("Unexpected read") }
    func fetchScriptWithSentences(id: Int64) async throws -> (script: Script, sentences: [Sentence]) {
        fatalError("Unexpected read")
    }
    func updateLastViewedAt(forScriptId scriptId: Int64) async throws { fatalError("Unexpected update") }
    func updateScriptTitle(scriptId: Int64, newTitle: String) async throws {}
    func fetchAllFeedbackSummaries() async throws -> [FeedbackSummary] { fatalError("Unexpected read") }
    func fetchFeedbackSummaries(forScriptId scriptId: Int64) async throws -> [FeedbackSummary] {
        fatalError("Unexpected read")
    }
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
    ) async throws -> FeedbackSummary {
        fatalError("Unexpected write")
    }
}
