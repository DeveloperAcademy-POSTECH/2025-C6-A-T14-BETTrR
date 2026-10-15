import Foundation

/// 분석 deadline은 단조 시계로, 호출 제한의 기록 시각은 달력 시계로 판단합니다.
@MainActor
protocol ScriptConfirmClock {
    var now: ContinuousClock.Instant { get }
    var date: Date { get }
    func sleep(until deadline: ContinuousClock.Instant) async throws
}

struct ContinuousScriptConfirmClock: ScriptConfirmClock {
    nonisolated init() {}

    var now: ContinuousClock.Instant { ContinuousClock.now }
    var date: Date { Date() }

    func sleep(until deadline: ContinuousClock.Instant) async throws {
        try await ContinuousClock().sleep(until: deadline)
    }
}
