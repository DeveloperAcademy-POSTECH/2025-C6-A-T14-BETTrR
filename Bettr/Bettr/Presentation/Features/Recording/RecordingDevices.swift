import Foundation

/// 마이크와 음성 인식 권한을 합친 상태입니다.
nonisolated enum RecordingPermissionStatus: Equatable, Sendable {
    case notDetermined
    case authorized
    case denied
}

/// 권한 조회·요청 경계입니다. `status`는 부작용이 없고, 요청은 명시적으로 호출할 때만 일어납니다.
@MainActor
protocol RecordingPermissionProviding: AnyObject {
    var status: RecordingPermissionStatus { get }
    func requestAuthorization() async -> RecordingPermissionStatus
}

nonisolated enum RecordingCaptureEvent: Equatable, Sendable {
    /// 인식 중인 중간 결과 전체 문자열
    case partial(String)
    /// 인식기가 최종 결과 또는 오류로 끝났습니다. 최종 문자열이 있으면 함께 전달합니다.
    case ended(String?)
}

nonisolated struct RecordingCaptureError: Error, Equatable {}

/// 오디오 입력과 음성 인식을 묶은 기기 경계입니다.
///
/// 이벤트는 `begin`이 만든 인식 한 번에만 속합니다. 구현은 `release` 이후와 새 `begin` 이후에
/// 이전 인식의 콜백을 전달하지 않아야 하며, ViewModel도 세션 ID로 한 번 더 걸러냅니다.
@MainActor
protocol RecordingCapturing: AnyObject {
    /// 오디오 세션·엔진·인식 작업을 시작합니다. 실패하면 리소스를 남기지 않고 throw합니다.
    func begin(onEvent: @escaping @MainActor (RecordingCaptureEvent) -> Void) throws
    /// 오디오 입력만 닫고 인식기의 마지막 결과(`ended`)를 기다립니다.
    func endAudio()
    /// 엔진·인식 작업·오디오 세션을 모두 정리합니다. 여러 번 호출해도 안전합니다.
    func release()
}

/// 녹음 타이머의 시간 원천입니다. 테스트에서 실제 대기 없이 시간을 진행합니다.
@MainActor
protocol RecordingClock {
    var now: ContinuousClock.Instant { get }
    func sleep(until deadline: ContinuousClock.Instant) async throws
}

struct ContinuousRecordingClock: RecordingClock {
    nonisolated init() {}

    var now: ContinuousClock.Instant { ContinuousClock.now }

    func sleep(until deadline: ContinuousClock.Instant) async throws {
        try await ContinuousClock().sleep(until: deadline)
    }
}
