import Foundation
import XCTest
@testable import Bettr

final class LocalRateLimiterTests: XCTestCase {
    func test_canCall_whenLimitIsReached_thenBlocksUntilWindowExpires() {
        let start = Date(timeIntervalSince1970: 0)
        let limiter = LocalRateLimiter(uuid: "test-device")

        XCTAssertTrue(limiter.canCall(at: start))
        XCTAssertTrue(limiter.canCall(at: start))
        XCTAssertTrue(limiter.canCall(at: start))
        XCTAssertFalse(limiter.canCall(at: start))

        XCTAssertTrue(limiter.canCall(at: start.addingTimeInterval(60)))
    }

    func test_reset_whenCallsWereRecorded_thenAllowsCallsAgain() {
        let limiter = LocalRateLimiter(uuid: "test-device")
        let start = Date(timeIntervalSince1970: 0)

        _ = limiter.canCall(at: start)
        _ = limiter.canCall(at: start)
        _ = limiter.canCall(at: start)
        limiter.reset()

        XCTAssertTrue(limiter.canCall(at: start))
    }
}
