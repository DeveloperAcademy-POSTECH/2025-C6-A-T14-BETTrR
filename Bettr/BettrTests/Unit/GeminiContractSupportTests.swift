import BettrAI
import XCTest
@testable import Bettr

@MainActor
final class GeminiContractSupportTests: XCTestCase {
    func test_deadlineReturnsBeforeNoncooperativeOperationAndIgnoresLateSuccess() async {
        let operation = ContractGate()
        let timer = ContractGate()
        let finished = expectation(description: "Deadline returns while provider is still waiting")
        let providerReturned = expectation(description: "Late provider result is discarded")
        var outcome: GeminiContractFailure?
        var completions = 0
        let task = Task {
            do {
                _ = try await GeminiContractDeadline.run(sleep: { await timer.wait() }, operation: {
                    await operation.wait() // Deliberately ignores task cancellation.
                    providerReturned.fulfill()
                    return 42
                })
            } catch {
                outcome = GeminiContractFailure(error: error)
            }
            completions += 1
            finished.fulfill()
        }
        await fulfillment(of: [operation.began, timer.began], timeout: 1)
        timer.release()
        await fulfillment(of: [finished], timeout: 1)
        XCTAssertEqual(outcome, .deadline)
        XCTAssertEqual(completions, 1)
        operation.release()
        await fulfillment(of: [providerReturned], timeout: 1)
        await task.value
        XCTAssertEqual(outcome, .deadline)
        XCTAssertEqual(completions, 1)
    }

    func test_parentCancellationReturnsBeforeNoncooperativeOperation() async {
        let operation = ContractGate()
        let timer = ContractGate()
        let finished = expectation(description: "Cancellation returns promptly")
        var outcome: GeminiContractFailure?
        let task = Task {
            do {
                _ = try await GeminiContractDeadline.run(sleep: { await timer.wait() }, operation: {
                    await operation.wait()
                    return 42
                })
            } catch {
                outcome = GeminiContractFailure(error: error)
            }
            finished.fulfill()
        }
        await fulfillment(of: [operation.began, timer.began], timeout: 1)
        task.cancel()
        await fulfillment(of: [finished], timeout: 1)
        XCTAssertEqual(outcome, .cancelled)
        operation.release()
        timer.release()
        await task.value
    }

    func test_successCancelsTimerAndKeepsFirstResult() async throws {
        let operation = ContractGate()
        let timer = ContractGate()
        let timerReturned = expectation(description: "Late timer is ignored")
        let task = Task {
            try await GeminiContractDeadline.run(sleep: {
                await timer.wait()
                timerReturned.fulfill()
            }, operation: {
                await operation.wait()
                return 42
            })
        }
        await fulfillment(of: [operation.began, timer.began], timeout: 1)
        operation.release()
        let value = try await task.value
        XCTAssertEqual(value, 42)
        timer.release()
        await fulfillment(of: [timerReturned], timeout: 1)
    }

    func test_errorIsReportedWithoutRetryOrOriginalErrorDescription() async {
        var calls = 0
        do {
            _ = try await GeminiContractDeadline<Int>.run {
                calls += 1
                throw NSError(domain: "untrusted-provider-error", code: 7)
            }
            XCTFail("Expected unknown failure")
        } catch {
            XCTAssertEqual(error as? GeminiContractFailure, .unknown)
        }
        XCTAssertEqual(calls, 1)
    }

    func test_failureCategoriesDistinguishSetupServiceAndContract() {
        let cases: [(Error, GeminiContractFailure)] = [
            (GeminiContractFailure.configuration, .configuration),
            (AIError.authentication, .authentication), (AIError.rateLimited, .quota),
            (AIError.transient, .serviceUnavailable), (AIError.responseContract, .responseContract),
            (AIError.cancelled, .cancelled), (CancellationError(), .cancelled)
        ]
        for (error, expected) in cases {
            XCTAssertEqual(GeminiContractFailure(error: error), expected)
        }
    }

    func test_environmentRequiresExplicitOptInAndRegisteredToken() throws {
        let token = "00000000-0000-4000-8000-000000000001"
        let valid = ["GEMINI_CONTRACT_ENABLED": "1", "AppCheckDebugToken": token]
        try GeminiContractConfiguration.validateEnvironment(valid)
        for environment in [[:], ["GEMINI_CONTRACT_ENABLED": "1"],
                            ["AppCheckDebugToken": token],
                            ["GEMINI_CONTRACT_ENABLED": "1", "AppCheckDebugToken": "$(FIREBASE_APP_CHECK_DEBUG_TOKEN)"],
                            valid.merging(
                                ["FIRAAppCheckDebugToken": "conflicting-token"],
                                uniquingKeysWith: { _, new in new }
                            )] {
            XCTAssertThrowsError(try GeminiContractConfiguration.validateEnvironment(environment)) {
                XCTAssertEqual($0 as? GeminiContractFailure, .configuration)
            }
        }
    }

    func test_plistPreflightRejectsMalformedConfigurationBeforeSDKInitialization() throws {
        let valid: [String: Any] = [
            "GOOGLE_APP_ID": "1:12345:ios:abcdef0123456789abcdef01",
            "API_KEY": String(repeating: "x", count: 39), "PROJECT_ID": "contract-fixture",
            "GCM_SENDER_ID": "12345", "BUNDLE_ID": "fixture.bundle"
        ]
        func data(_ values: [String: Any]) throws -> Data {
            try PropertyListSerialization.data(fromPropertyList: values, format: .xml, options: 0)
        }
        try GeminiContractConfiguration.validatePlist(data(valid), bundleIdentifier: "fixture.bundle")
        for (key, value) in [("GOOGLE_APP_ID", "invalid"), ("GOOGLE_APP_ID", "1:12345:ios:not-hex"),
                             ("API_KEY", ""), ("PROJECT_ID", " "), ("GCM_SENDER_ID", "not-a-number"),
                             ("BUNDLE_ID", "another.bundle")] {
            var invalid = valid
            invalid[key] = value
            XCTAssertThrowsError(try GeminiContractConfiguration.validatePlist(
                data(invalid), bundleIdentifier: "fixture.bundle"
            )) {
                XCTAssertEqual($0 as? GeminiContractFailure, .configuration)
            }
        }
        for key in valid.keys {
            var invalid = valid
            invalid.removeValue(forKey: key)
            XCTAssertThrowsError(try GeminiContractConfiguration.validatePlist(
                data(invalid), bundleIdentifier: "fixture.bundle"
            ))
            invalid[key] = 123
            XCTAssertThrowsError(try GeminiContractConfiguration.validatePlist(
                data(invalid), bundleIdentifier: "fixture.bundle"
            ))
        }
        XCTAssertThrowsError(try GeminiContractConfiguration.validatePlist(
            Data("malformed".utf8), bundleIdentifier: "fixture.bundle"
        ))
    }
}

@MainActor
private final class ContractGate {
    let began = XCTestExpectation(description: "Suspended operation began")
    private var continuation: CheckedContinuation<Void, Never>?

    func wait() async {
        await withCheckedContinuation { continuation in
            self.continuation = continuation
            began.fulfill()
        }
    }

    func release() {
        continuation?.resume()
        continuation = nil
    }
}
