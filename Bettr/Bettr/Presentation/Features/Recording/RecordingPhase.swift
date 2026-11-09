import Foundation

/// 녹음 한 번(세션)의 진행 단계입니다. 기기·타이머·저장 작업과 무관한 순수 값입니다.
///
/// `idle → requestingPermission → recording → finishing → resultReady → saving → completed`가
/// 기본 흐름이며, 실패는 `failed`로 표현합니다. 허용되지 않은 전이는 `nil`로 거부하므로
/// 중복 시작·종료·취소와 늦은 콜백이 다른 단계를 바꾸지 못합니다.
nonisolated enum RecordingPhase: Equatable {
    case idle
    case requestingPermission
    case recording
    /// 오디오 입력은 끝났고 음성 인식의 마지막 결과를 기다립니다.
    case finishing
    case resultReady
    /// 평가와 저장입니다. 저장 시작 후에는 취소로 커밋을 되돌릴 수 없습니다.
    case saving
    case completed
    case failed(RecordingFailure)

    /// 이벤트로 이동할 다음 단계입니다. 현재 단계에서 허용되지 않으면 nil입니다.
    func transitioned(on event: RecordingEvent) -> RecordingPhase? {
        switch (self, event) {
        case (.idle, .startRequested):
            return .requestingPermission
        case (.requestingPermission, .captureStarted):
            return .recording
        case (.requestingPermission, .permissionDenied):
            return .failed(.permissionDenied)
        case (.requestingPermission, .captureFailed):
            return .failed(.captureUnavailable)

        case (.recording, .stopRequested):
            return .finishing
        // 사용자 종료 없이 인식기가 끝나는 경우(오류·시간 제한)도 결과로 마무리합니다.
        case (.recording, .recognitionEnded), (.finishing, .recognitionEnded):
            return .resultReady

        case (.resultReady, .saveRequested):
            return .saving
        case (.saving, .emptyResult):
            return .failed(.emptyTranscript)
        case (.saving, .saveSucceeded):
            return .completed
        case (.saving, .saveFailed):
            return .failed(.saveFailed)
        case (.saving, .saveOutcomeUnknown):
            return .failed(.saveOutcomeUnknown)

        // 저장이 시작된 뒤에는 되돌릴 수 없으므로 saving은 reset을 거부합니다.
        case (.idle, .reset), (.requestingPermission, .reset), (.recording, .reset),
             (.finishing, .reset), (.resultReady, .reset), (.completed, .reset), (.failed, .reset):
            return .idle

        case (.failed(let failure), .failureDismissed):
            return failure.recoveryPhase
        default:
            return nil
        }
    }

    /// 실패 알림 아래에서 화면이 보여줄 단계입니다.
    var displayed: RecordingPhase {
        if case .failed(let failure) = self { return failure.recoveryPhase }
        return self
    }
}

nonisolated enum RecordingFailure: Equatable {
    case permissionDenied
    case captureUnavailable
    case emptyTranscript
    /// 실패가 확인된 저장입니다. 같은 결과로 다시 저장할 수 있습니다.
    case saveFailed
    /// 커밋 여부를 알 수 없습니다. 중복 저장을 막기 위해 재시도를 허용하지 않습니다.
    case saveOutcomeUnknown

    /// 사용자가 알림을 확인한 뒤 돌아갈 단계입니다. 확인된 저장 실패만 결과를 유지해 재시도할 수 있습니다.
    var recoveryPhase: RecordingPhase {
        self == .saveFailed ? .resultReady : .idle
    }
}

nonisolated enum RecordingEvent: Equatable {
    case startRequested
    case captureStarted
    case captureFailed
    case permissionDenied
    case stopRequested
    case recognitionEnded
    case saveRequested
    case emptyResult
    case saveSucceeded
    case saveFailed
    case saveOutcomeUnknown
    case failureDismissed
    case reset
}
