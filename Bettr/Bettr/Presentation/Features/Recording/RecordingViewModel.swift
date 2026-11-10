//
//  RecordingViewModel.swift
//  Bettr
//
//  Created by 길정수 on 10/30/25.
//

import Foundation
import Observation

/// 저장이 성공했을 때 한 번만 전달하는 완료 결과입니다.
struct RecordingCompletion: Equatable {
    let summaryID: Int64
}

/// 녹음 한 번의 단계 전이와 수명을 소유합니다. 권한·마이크·음성 인식·시간은 주입된 경계가
/// 담당하고, View는 입력을 전달하며 상태와 완료 결과만 표시합니다.
///
/// 정책은 [ADR 0005](../../../../../docs/decisions/0005-recording-session-workflow.md)를 따릅니다.
@MainActor
@Observable
final class RecordingViewModel {
    // MARK: - Observable state

    private(set) var phase = RecordingPhase.idle
    private(set) var transcript = ""
    private(set) var elapsedTime: TimeInterval = 0
    let sentences: [String]

    // MARK: - Dependencies

    private let scriptId: Int64
    private let permissions: any RecordingPermissionProviding
    private let capture: any RecordingCapturing
    private let clock: any RecordingClock
    private let analyzer: SpeechAnalyzer
    private let processor: RecordingProcessor
    private let scriptManagementService: ScriptManagementServiceProtocol

    // MARK: - Session state

    /// 현재 녹음 세션입니다. 콜백과 비동기 결과는 이 값과 일치할 때만 반영됩니다.
    private var sessionID: UUID?
    private var recordingStart: ContinuousClock.Instant?
    private var recordedDuration: TimeInterval = 0
    private var pendingCompletion: RecordingCompletion?
    private var hasLeft = false
    @ObservationIgnored private var tickerTask: Task<Void, Never>?
    @ObservationIgnored private var permissionTask: Task<Void, Never>?
    @ObservationIgnored private var saveTask: Task<Void, Never>?

    private static let tickInterval = Duration.milliseconds(10)

    // 다른 MainActor 모델과 같은 iOS 26.2 deinit 런타임 우회입니다.
    nonisolated deinit {}

    // MARK: - Derived state for the view

    var isRecording: Bool { phase == .recording }
    var isLoading: Bool { phase == .saving }

    /// 알림이 떠 있는 동안에는 알림을 확인한 뒤 돌아갈 단계를 기준으로 화면을 그립니다.
    private var displayedPhase: RecordingPhase { phase.displayed }

    /// 녹음 대기 상태인지 확인 (녹음 중도 아니고, 완료된 녹음도 없음)
    var isReadyToRecord: Bool {
        displayedPhase == .idle || displayedPhase == .requestingPermission
    }

    /// 녹음이 끝나 결과가 있는 상태인지 확인
    var hasRecorded: Bool {
        switch displayedPhase {
        case .resultReady, .saving, .completed: true
        default: false
        }
    }

    var canToggleRecording: Bool { displayedPhase == .idle || displayedPhase == .recording }
    var canReset: Bool { displayedPhase == .resultReady }
    var canSave: Bool { displayedPhase == .resultReady }

    var failure: RecordingFailure? {
        if case .failed(let failure) = phase { return failure }
        return nil
    }

    var errorMessage: String? {
        switch failure {
        case .captureUnavailable:
            "녹음을 시작하지 못했습니다.\n다른 앱이 마이크를 사용 중인지 확인해 주세요."
        case .saveFailed:
            "저장 중 문제가 발생했습니다.\n잠시 후 다시 시도해 주세요."
        case .saveOutcomeUnknown:
            "저장 결과를 확인하지 못했습니다.\n중복 저장을 막기 위해 피드백 기록에서 저장 여부를 확인해 주세요."
        case .permissionDenied, .emptyTranscript, nil:
            nil
        }
    }

    /// 화면 이탈 뒤에 끝난 저장은 화면 이동으로 이어지지 않습니다.
    var completion: RecordingCompletion? { hasLeft ? nil : pendingCompletion }

    /// 전체 스크립트 (분석용 결합 문자열)
    var fullScript: String { sentences.joined(separator: " ") }

    // MARK: - Initializer

    /// 권한 요청 같은 부작용 없이 상태만 만듭니다.
    /// - Parameters:
    ///   - scriptId: 피드백을 연결할 스크립트 ID. 세션 동안 고정됩니다.
    ///   - sentences: 연습할 스크립트의 문장 배열
    init(
        scriptId: Int64,
        sentences: [String],
        scriptManagementService: ScriptManagementServiceProtocol,
        permissions: any RecordingPermissionProviding,
        capture: any RecordingCapturing,
        clock: any RecordingClock = ContinuousRecordingClock()
    ) {
        let analyzer = SpeechAnalyzer()
        self.scriptId = scriptId
        self.sentences = sentences
        self.scriptManagementService = scriptManagementService
        self.permissions = permissions
        self.capture = capture
        self.clock = clock
        self.analyzer = analyzer
        self.processor = RecordingProcessor(analyzer: analyzer)
    }

    // MARK: - User actions

    /// 녹음 상태를 토글 (시작 <-> 종료). 진행 중인 전이에는 무시합니다.
    func toggleRecording() {
        switch phase {
        case .idle: startSession()
        case .recording: stopRecording()
        default: break
        }
    }

    /// 녹음 결과를 버리고 처음 상태로 돌아갑니다. 저장이 시작된 뒤에는 무시합니다.
    func cancelRecording() {
        guard apply(.reset) else { return }
        tearDownSession()
    }

    /// 인식 결과를 평가하고 저장합니다. 저장은 View 생명주기와 무관한 Task에서 실행됩니다.
    func saveFeedback() {
        guard apply(.saveRequested), let sessionID else { return }

        let diffs = analyzer.analyze(reference: fullScript, recognizedText: transcript)
        guard !diffs.isEmpty else {
            apply(.emptyResult)
            return
        }
        let stats = processor.createSummaryStats(
            fromLiveAnalysis: diffs,
            sentences: sentences,
            practiceDuration: recordedDuration
        )

        // 구조화되지 않은 Task가 저장이 끝날 때까지 self를 유지해 실제 commit/rollback 결과를 반영합니다.
        saveTask = Task {
            let outcome: SaveOutcome
            do {
                let summary = try await scriptManagementService.createFeedbackSummary(
                    scriptId: scriptId,
                    accuracy: stats.accuracy,
                    missingWordCount: stats.missingCount,
                    addedWordCount: stats.extraCount,
                    replacedWordCount: stats.replacedCount,
                    practiceDuration: stats.practiceDuration,
                    feedbackDetailsData: stats.dbDetails.map {
                        ($0.wordDiff, $0.originalText, $0.sentenceIndex, $0.wordIndex)
                    }
                )
                outcome = summary.id.map(SaveOutcome.saved) ?? .unknown
            } catch is CancellationError {
                outcome = .unknown
            } catch {
                outcome = .failed
            }
            finishSave(outcome, sessionID: sessionID)
        }
    }

    /// 실패 알림을 확인했을 때 호출합니다. 실패 종류에 따라 이전 단계로 돌아갑니다.
    func dismissFailure() {
        guard apply(.failureDismissed) else { return }
        if phase == .idle { tearDownSession() }
    }

    func consumeCompletion() -> RecordingCompletion? {
        defer { pendingCompletion = nil }
        return completion
    }

    /// 화면 이탈 시 호출합니다. 녹음·타이머 리소스를 정리하고, 저장 중이면 결과만 기록한 채
    /// 완료 전달을 막습니다. 이미 시작된 저장은 취소할 수 없습니다.
    func leave() {
        hasLeft = true
        pendingCompletion = nil
        switch phase {
        case .saving, .completed:
            break
        default:
            apply(.reset)
            tearDownSession()
        }
    }

    // MARK: - Session lifecycle

    private func startSession() {
        guard apply(.startRequested) else { return }
        let sessionID = UUID()
        self.sessionID = sessionID
        hasLeft = false
        pendingCompletion = nil
        resetSessionData()

        switch permissions.status {
        case .authorized:
            beginCapture(sessionID: sessionID)
        case .denied:
            denyPermission()
        case .notDetermined:
            permissionTask = Task { [weak self, permissions] in
                let status = await permissions.requestAuthorization()
                self?.permissionResolved(status, sessionID: sessionID)
            }
        }
    }

    private func permissionResolved(_ status: RecordingPermissionStatus, sessionID: UUID) {
        guard self.sessionID == sessionID, phase == .requestingPermission else { return }
        permissionTask = nil
        if status == .authorized {
            beginCapture(sessionID: sessionID)
        } else {
            denyPermission()
        }
    }

    private func denyPermission() {
        apply(.permissionDenied)
        self.sessionID = nil
    }

    private func beginCapture(sessionID: UUID) {
        do {
            try capture.begin { [weak self] event in
                self?.handle(event, sessionID: sessionID)
            }
        } catch {
            capture.release()
            apply(.captureFailed)
            self.sessionID = nil
            return
        }
        apply(.captureStarted)
        startTicker(sessionID: sessionID)
    }

    private func stopRecording() {
        guard apply(.stopRequested) else { return }
        freezeElapsedTime()
        stopTicker()
        capture.endAudio()
    }

    private func handle(_ event: RecordingCaptureEvent, sessionID: UUID) {
        // 다른 세션이나 이미 끝난 인식의 늦은 콜백은 현재 상태를 바꾸지 못합니다.
        guard self.sessionID == sessionID, phase == .recording || phase == .finishing else { return }
        switch event {
        case .partial(let text):
            transcript = text
        case .ended(let text):
            if let text { transcript = text }
            freezeElapsedTime()
            stopTicker()
            capture.release()
            apply(.recognitionEnded)
        }
    }

    private func finishSave(_ outcome: SaveOutcome, sessionID: UUID) {
        saveTask = nil
        guard self.sessionID == sessionID, phase == .saving else { return }
        switch outcome {
        case .saved(let summaryID):
            apply(.saveSucceeded)
            if !hasLeft { pendingCompletion = RecordingCompletion(summaryID: summaryID) }
        case .failed:
            AppLog.database.error("피드백 저장 실패")
            apply(.saveFailed)
        case .unknown:
            AppLog.database.error("피드백 저장 결과 확인 불가")
            apply(.saveOutcomeUnknown)
        }
    }

    // MARK: - Timer

    private func startTicker(sessionID: UUID) {
        recordingStart = clock.now
        elapsedTime = 0
        tickerTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let clock = self?.clock else { return }
                do {
                    try await clock.sleep(until: clock.now.advanced(by: Self.tickInterval))
                } catch {
                    return
                }
                guard let self, self.sessionID == sessionID, self.phase == .recording,
                      let start = self.recordingStart else { return }
                self.elapsedTime = Self.seconds(from: start, to: self.clock.now)
            }
        }
    }

    private func stopTicker() {
        tickerTask?.cancel()
        tickerTask = nil
    }

    /// 사용자가 종료한 시점(또는 인식기가 끝난 시점)의 시간을 고정합니다.
    private func freezeElapsedTime() {
        guard let start = recordingStart else { return }
        elapsedTime = Self.seconds(from: start, to: clock.now)
        recordedDuration = elapsedTime
        recordingStart = nil
    }

    private static func seconds(from start: ContinuousClock.Instant, to end: ContinuousClock.Instant) -> TimeInterval {
        let components = (end - start).components
        return Double(components.seconds) + Double(components.attoseconds) / 1e18
    }

    // MARK: - Helpers

    private enum SaveOutcome {
        case saved(Int64)
        case failed
        case unknown
    }

    @discardableResult
    private func apply(_ event: RecordingEvent) -> Bool {
        guard let next = phase.transitioned(on: event) else { return false }
        phase = next
        return true
    }

    /// 타이머·권한 요청·녹음 장치를 정리하고 세션을 무효화합니다.
    private func tearDownSession() {
        sessionID = nil
        stopTicker()
        permissionTask?.cancel()
        permissionTask = nil
        capture.release()
        resetSessionData()
    }

    private func resetSessionData() {
        transcript = ""
        elapsedTime = 0
        recordedDuration = 0
        recordingStart = nil
    }
}
