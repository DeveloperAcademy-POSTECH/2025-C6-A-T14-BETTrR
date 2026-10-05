import Foundation
import XCTest
@testable import Bettr

@MainActor
final class GeminiRetryExecutorTests: XCTestCase {
    func test_perform_whenTransientFailureThenSuccess_thenRetriesWithoutRealSleep() async throws {
        let sleeper = RecordingSleeper()
        let executor = GeminiRetryExecutor(sleeper: sleeper)
        let attempts = AttemptCounter()

        let result = try await executor.perform {
            if await attempts.next() == 1 {
                throw AIError.transient
            }

            return "success"
        }

        let attemptCount = await attempts.count
        XCTAssertEqual(result, "success")
        XCTAssertEqual(attemptCount, 2)
        let durations = await sleeper.durations
        XCTAssertEqual(durations, [1])
    }

    func test_perform_whenResponseContractFailsTwice_thenStopsAfterMaximumAttempts() async {
        let sleeper = RecordingSleeper()
        let executor = GeminiRetryExecutor(sleeper: sleeper)
        let attempts = AttemptCounter()

        await XCTAssertThrowsAIError(.responseContract) {
            let _: String = try await executor.perform {
                _ = await attempts.next()
                throw AIError.responseContract
            }
        }

        let attemptCount = await attempts.count
        XCTAssertEqual(attemptCount, 2)
        let durations = await sleeper.durations
        XCTAssertEqual(durations, [1])
    }

    func test_perform_whenAuthenticationFails_thenDoesNotRetry() async {
        let sleeper = RecordingSleeper()
        let executor = GeminiRetryExecutor(sleeper: sleeper)
        let attempts = AttemptCounter()

        await XCTAssertThrowsAIError(.authentication) {
            let _: String = try await executor.perform {
                _ = await attempts.next()
                throw AIError.authentication
            }
        }

        let attemptCount = await attempts.count
        XCTAssertEqual(attemptCount, 1)
        let durations = await sleeper.durations
        XCTAssertTrue(durations.isEmpty)
    }

    func test_perform_whenSleepIsCancelled_thenThrowsCancelled() async {
        let sleeper = RecordingSleeper(error: .cancelled)
        let executor = GeminiRetryExecutor(sleeper: sleeper)

        await XCTAssertThrowsAIError(.cancelled) {
            let _: String = try await executor.perform {
                throw AIError.transient
            }
        }

        let durations = await sleeper.durations
        XCTAssertEqual(durations, [1])
    }

    func test_perform_whenCancelledWhileWaiting_thenDoesNotStartAnotherAttempt() async {
        let sleeper = ControlledSleeper()
        let executor = GeminiRetryExecutor(sleeper: sleeper)
        let attempts = AttemptCounter()
        let task = Task {
            try await executor.perform {
                _ = await attempts.next()
                throw AIError.transient
            }
        }
        await sleeper.waitUntilSleeping()
        task.cancel()
        await sleeper.resume()
        await XCTAssertThrowsAIError(.cancelled) { _ = try await task.value }
        let attemptCount = await attempts.count
        XCTAssertEqual(attemptCount, 1)
    }

    func test_perform_whenCancelledBeforeCall_thenDoesNotStartAttempt() async {
        let executor = GeminiRetryExecutor()
        let attempts = AttemptCounter()
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await executor.perform { await attempts.next() }
        }
        await XCTAssertThrowsAIError(.cancelled) { _ = try await task.value }
        let attemptCount = await attempts.count
        XCTAssertEqual(attemptCount, 0)
    }

}

private func XCTAssertThrowsAIError(
    _ expectedError: AIError,
    _ expression: () async throws -> Void,
    file: StaticString = #filePath,
    line: UInt = #line
) async {
    do {
        try await expression()
        XCTFail("Expected \(expectedError) to be thrown.", file: file, line: line)
    } catch let error as AIError {
        XCTAssertEqual(error, expectedError, file: file, line: line)
    } catch {
        XCTFail("Expected AIError, got \(error).", file: file, line: line)
    }
}

private actor AttemptCounter {
    private(set) var count = 0

    func next() -> Int {
        count += 1
        return count
    }
}

private actor RecordingSleeper: GeminiSleeping {
    private let error: AIError?
    private(set) var durations: [TimeInterval] = []

    init(error: AIError? = nil) {
        self.error = error
    }

    func sleep(for duration: TimeInterval) throws {
        durations.append(duration)
        if let error { throw error }
    }
}

private actor ControlledSleeper: GeminiSleeping {
    private var sleeping: CheckedContinuation<Void, Never>?
    private var started: CheckedContinuation<Void, Never>?

    func sleep(for duration: TimeInterval) async {
        await withCheckedContinuation { continuation in
            sleeping = continuation
            started?.resume()
            started = nil
        }
    }

    func waitUntilSleeping() async {
        if sleeping != nil { return }
        await withCheckedContinuation { started = $0 }
    }

    func resume() {
        sleeping?.resume()
        sleeping = nil
    }
}
