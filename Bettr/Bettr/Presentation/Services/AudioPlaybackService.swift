//
//  AudioPlaybackService.swift
//  Bettr
//
//  Created by 길정수 on 11/3/25.
//

import BettrAI
import AVFoundation

/// 암기 화면 재생 상태의 유일한 소유자입니다. 파생 규칙은 `AudioPlaybackServiceProtocol`을 따릅니다.
///
/// 합성기 이벤트는 현재 발화(`currentUtterance`)와 일치할 때만 반영하므로,
/// 이전 재생의 늦은 종료·취소 콜백은 새 재생의 상태를 바꾸지 못합니다.
@MainActor
@Observable
final class AudioPlaybackService: AudioPlaybackServiceProtocol {
    private(set) var isPlaybackActive: Bool = false
    private(set) var isPaused: Bool = false
    private(set) var currentPlaybackMode: PlaybackMode = .stopped

    /// 전체 재생 모드에서만 사용되는 현재 문장 인덱스
    private(set) var currentMultiSentenceIndex: Int? = nil

    /// 현재 재생 중인 대상의 고유 ID (단일 재생에서만 값이 있습니다)
    private(set) var currentPlaybackID: PlaybackTargetID? = nil

    /// 현재까지 재생된 텍스트 범위 (NSRange)
    private(set) var currentSpokenRange: NSRange? = nil

    @ObservationIgnored private let synthesizer: any SpeechSynthesizing
    @ObservationIgnored private var utteranceQueue: [(index: Int, utterance: AVSpeechUtterance)] = []

    /// 현재 재생 중인 '객체' 자체
    @ObservationIgnored private var currentUtterance: AVSpeechUtterance? = nil

    /// 문장 사이 대기 중인 다음 문장 시작 작업
    @ObservationIgnored private var advanceTask: Task<Void, Never>? = nil

    /// 문장 사이 대기 중에 일시정지되어, 재개할 때 다음 문장부터 시작해야 하는지 여부
    @ObservationIgnored private var isAdvancePending = false

    /// 발화 속도 (기본 0.5보다 느리게 설정)
    private let speechRate: Float = 0.45

    /// 문장과 문장 사이 딜레이
    private let interSentenceDelay: Duration

    init(
        synthesizer: (any SpeechSynthesizing)? = nil,
        interSentenceDelay: Duration = .milliseconds(500)
    ) {
        let synthesizer = synthesizer ?? SystemSpeechSynthesizer()
        self.synthesizer = synthesizer
        self.interSentenceDelay = interSentenceDelay
        synthesizer.onEvent = { [weak self] event in
            self?.handle(event)
        }
    }

    // --- Private Session Helpers ---

    /// 재생 세션을 활성화하고 카테고리를 .playback으로 설정합니다.
    private func activatePlaybackSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            AppLog.audio.error("재생 오디오 세션 활성화 실패")
        }
    }

    /// 오디오 세션을 비활성화합니다. (다른 앱이 오디오를 사용할 수 있도록)
    private func deactivateSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            AppLog.audio.error("재생 오디오 세션 비활성화 실패")
        }
    }

    // --- Public API ---

    /// 특정 텍스트 하나만 재생합니다. (청크 또는 문장 탭 시 사용)
    func play(text: String, id: PlaybackTargetID, language: String = "en-US") {
        cancelPendingAdvance()
        utteranceQueue.removeAll()
        isPaused = false
        currentMultiSentenceIndex = nil
        currentSpokenRange = nil
        currentPlaybackMode = .single
        currentPlaybackID = id

        let utterance = createUtterance(text: text, language: language)
        currentUtterance = utterance

        synthesizer.stopSpeaking()
        activatePlaybackSession()
        synthesizer.speak(utterance)
    }

    /// 스크립트 전체 문장을 순서대로 재생합니다. (전체 재생 버튼용)
    func playAll(sentences: [SentenceData], language: String = "en-US") {
        cancelPendingAdvance()
        currentUtterance = nil
        synthesizer.stopSpeaking()

        isPaused = false
        currentPlaybackMode = .multi
        currentPlaybackID = nil
        currentMultiSentenceIndex = nil
        currentSpokenRange = nil

        activatePlaybackSession()

        utteranceQueue = sentences
            .sorted { $0.orderIndex < $1.orderIndex }
            .map { (index: $0.orderIndex, utterance: createUtterance(text: $0.englishText, language: language)) }

        AppLog.audio.debug("대기열 재생 시작")

        playNextInQueue()
    }

    /// 재생을 일시 중지합니다.
    func pause() {
        guard currentPlaybackMode != .stopped, !isPaused else { return }

        if synthesizer.isSpeaking {
            synthesizer.pauseSpeaking()
        } else if advanceTask != nil {
            cancelPendingAdvance()
            isAdvancePending = true
        } else {
            return
        }

        isPaused = true
        deactivateSession()
    }

    /// 일시 중지된 지점부터 다시 재생합니다.
    func resume() {
        guard isPaused else { return }

        isPaused = false
        activatePlaybackSession()

        if isAdvancePending {
            isAdvancePending = false
            playNextInQueue()
        } else {
            synthesizer.continueSpeaking()
        }
    }

    /// 재생을 완전히 중지하고 큐를 비웁니다.
    func stop() {
        synthesizer.stopSpeaking()
        resetState()
    }

    // --- Synthesizer Events ---

    /// 현재 발화의 이벤트만 반영합니다. 이전 재생의 늦은 이벤트는 무시합니다.
    func handle(_ event: SpeechEvent) {
        guard let currentUtterance, ObjectIdentifier(currentUtterance) == event.utteranceID else { return }

        switch event.kind {
        case .didStart:
            isPlaybackActive = true
            currentSpokenRange = NSRange(location: 0, length: 0)

        case .willSpeak(let range):
            // "지금까지 말한 범위" = 시작점(0)부터 방금 말한 범위의 끝까지
            currentSpokenRange = NSRange(location: 0, length: range.location + range.length)

        case .didFinish:
            AppLog.audio.debug("대기열 음성 재생 완료")
            if currentPlaybackMode == .multi && !utteranceQueue.isEmpty {
                scheduleNextInQueue(after: currentUtterance)
            } else {
                resetState()
            }

        case .didPause:
            isPaused = true

        case .didContinue:
            isPlaybackActive = true
            isPaused = false

        case .didCancel:
            resetState()
        }
    }

    // --- Private Helpers ---

    private func resetState() {
        cancelPendingAdvance()
        isAdvancePending = false
        utteranceQueue.removeAll()
        currentUtterance = nil
        isPlaybackActive = false
        isPaused = false
        currentPlaybackMode = .stopped
        currentPlaybackID = nil
        currentMultiSentenceIndex = nil
        currentSpokenRange = nil
        deactivateSession()
    }

    private func cancelPendingAdvance() {
        advanceTask?.cancel()
        advanceTask = nil
    }

    private func createUtterance(text: String, language: String) -> AVSpeechUtterance {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = self.speechRate
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        return utterance
    }

    /// 문장 사이 딜레이 뒤에 다음 문장을 시작합니다. 그사이 정지·전환되면 시작하지 않습니다.
    private func scheduleNextInQueue(after completed: AVSpeechUtterance) {
        cancelPendingAdvance()
        advanceTask = Task { [weak self, interSentenceDelay] in
            try? await Task.sleep(for: interSentenceDelay)
            guard !Task.isCancelled, let self,
                  self.currentPlaybackMode == .multi,
                  self.currentUtterance === completed else { return }
            self.advanceTask = nil
            self.playNextInQueue()
        }
    }

    // utteranceQueue를 순서대로 처리
    private func playNextInQueue() {
        guard !utteranceQueue.isEmpty else {
            AppLog.audio.debug("대기열이 비어 재생 중지")
            resetState()
            return
        }

        let (index, utterance) = utteranceQueue.removeFirst()
        AppLog.audio.debug("대기열 음성 재생 시작")

        currentMultiSentenceIndex = index
        currentSpokenRange = nil
        currentUtterance = utterance
        isPlaybackActive = true

        synthesizer.speak(utterance)
    }
}
