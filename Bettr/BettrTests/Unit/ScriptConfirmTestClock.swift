import Foundation
import Observation
@testable import Bettr

@MainActor @Observable
final class ScriptConfirmTestClock: ScriptConfirmClock {
    let origin = ContinuousClock.now
    var now: ContinuousClock.Instant
    var date = Date(timeIntervalSince1970: 1_800_000_000)
    private(set) var deadlines: [ContinuousClock.Instant] = []
    private(set) var returnedSleeps: Set<Int> = []
    @ObservationIgnored private var pending: [Int: CheckedContinuation<Void, Error>] = [:]

    init() {
        now = origin
    }

    // Deliberately ignores Task cancellation so tests can deliver obsolete timers.
    func sleep(until deadline: ContinuousClock.Instant) async throws {
        try Task.checkCancellation()
        let index = deadlines.count
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            pending[index] = continuation
            deadlines.append(deadline)
        }
        returnedSleeps.insert(index)
    }

    func advance(seconds: Int) {
        now = now.advanced(by: .seconds(seconds))
        date = date.addingTimeInterval(TimeInterval(seconds))
    }

    func wake(_ index: Int) {
        pending.removeValue(forKey: index)?.resume()
    }

    func finishPending() {
        let continuations = Array(pending.values)
        pending.removeAll()
        for continuation in continuations { continuation.resume(throwing: CancellationError()) }
    }
}

