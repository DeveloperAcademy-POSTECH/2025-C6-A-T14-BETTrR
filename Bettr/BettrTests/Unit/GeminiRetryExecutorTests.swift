import Foundation
import XCTest
@testable import Bettr

final class GeminiRetryExecutorTests: XCTestCase {
    func test_perform_whenTransientFailureThenSuccess_thenRetriesWithoutRealSleep() async {
        let sleeper = RecordingSleeper()
        let executor = GeminiRetryExecutor(sleeper: sleeper)
        let attempts = AttemptCounter()

        let result = await executor.perform {
            if await attempts.next() == 1 {
                throw URLError(.timedOut)
            }

            return "success"
        }

        let attemptCount = await attempts.count
        let durations = await sleeper.durations
        XCTAssertEqual(result, "success")
        XCTAssertEqual(attemptCount, 2)
        XCTAssertEqual(durations, [1])
    }

    func test_perform_whenParsingFailsTwice_thenStopsAfterMaximumAttempts() async {
        let sleeper = RecordingSleeper()
        let executor = GeminiRetryExecutor(sleeper: sleeper)
        let attempts = AttemptCounter()

        let result: String? = await executor.perform {
            _ = await attempts.next()
            throw URLError(.cannotParseResponse)
        }

        let attemptCount = await attempts.count
        let durations = await sleeper.durations
        XCTAssertNil(result)
        XCTAssertEqual(attemptCount, 2)
        XCTAssertEqual(durations, [1])
    }

    func test_perform_whenAuthenticationFails_thenDoesNotRetry() async {
        let sleeper = RecordingSleeper()
        let executor = GeminiRetryExecutor(sleeper: sleeper)
        let attempts = AttemptCounter()

        let result: String? = await executor.perform {
            _ = await attempts.next()
            throw NSError(
                domain: "Firebase",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "unauthenticated"]
            )
        }

        let attemptCount = await attempts.count
        let durations = await sleeper.durations
        XCTAssertNil(result)
        XCTAssertEqual(attemptCount, 1)
        XCTAssertTrue(durations.isEmpty)
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
    private(set) var durations: [TimeInterval] = []

    func sleep(for duration: TimeInterval) {
        durations.append(duration)
    }
}
