import BettrAI
import Foundation
@testable import Bettr

/// Only fixed categories cross into XCTest output; SDK errors and payloads stay private.
nonisolated enum GeminiContractFailure: String, Error {
    case configuration
    case authentication
    case quota
    case serviceUnavailable
    case deadline
    case responseContract
    case cancelled
    case unknown

    init(error: Error) {
        if let failure = error as? Self {
            self = failure
            return
        }
        switch error as? AIError {
        case .authentication: self = .authentication
        case .rateLimited: self = .quota
        case .transient: self = .serviceUnavailable
        case .responseContract, .invalidInput: self = .responseContract
        case .cancelled: self = .cancelled
        default: self = error is CancellationError ? .cancelled : .unknown
        }
    }
}

nonisolated enum GeminiContractConfiguration {
    static func validateEnvironment(_ environment: [String: String]) throws {
        guard environment["GEMINI_CONTRACT_ENABLED"] == "1",
              let token = environment["AppCheckDebugToken"], UUID(uuidString: token) != nil,
              environment["FIRAAppCheckDebugToken"].map({ $0 == token }) ?? true else {
            throw GeminiContractFailure.configuration
        }
    }

    /// FirebaseOptions parses a plist but can still raise an Objective-C exception at configure.
    static func validatePlist(_ data: Data, bundleIdentifier: String) throws {
        guard let values = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
              let appID = values["GOOGLE_APP_ID"] as? String,
              appID.range(of: #"^1:[0-9]+:ios:[0-9a-fA-F]+$"#, options: .regularExpression) != nil,
              let apiKey = values["API_KEY"] as? String, apiKey.count == 39,
              let project = values["PROJECT_ID"] as? String, !project.trimmingCharacters(in: .whitespaces).isEmpty,
              let sender = values["GCM_SENDER_ID"] as? String, !sender.isEmpty,
              sender.allSatisfy(\.isNumber),
              values["BUNDLE_ID"] as? String == bundleIdentifier else {
            throw GeminiContractFailure.configuration
        }
    }
}

/// An unstructured race can stop waiting even if the SDK ignores task cancellation.
/// The operation only returns a value: assertions and state changes occur after this gate.
@MainActor
final class GeminiContractDeadline<Value> {
    private var continuation: CheckedContinuation<Value, Error>?
    private var operationTask: Task<Void, Never>?
    private var timerTask: Task<Void, Never>?

    static func run(
        timeout: Duration = .seconds(60),
        sleep: (@MainActor () async throws -> Void)? = nil,
        operation: @escaping @MainActor () async throws -> Value
    ) async throws -> Value {
        let race = GeminiContractDeadline()
        return try await withTaskCancellationHandler {
            guard !Task.isCancelled else { throw GeminiContractFailure.cancelled }
            return try await withCheckedThrowingContinuation { continuation in
                race.continuation = continuation
                race.operationTask = Task {
                    do {
                        let value = try await operation()
                        race.finish(.success(value))
                    } catch {
                        race.finish(.failure(GeminiContractFailure(error: error)))
                    }
                }
                race.timerTask = Task {
                    do {
                        if let sleep {
                            try await sleep()
                        } else {
                            try await Task.sleep(for: timeout)
                        }
                        race.finish(.failure(GeminiContractFailure.deadline))
                    } catch {
                        // A completed/cancelled race cancels the timer, without another result.
                    }
                }
            }
        } onCancel: {
            Task { @MainActor in race.finish(.failure(GeminiContractFailure.cancelled)) }
        }
    }

    private func finish(_ result: Result<Value, Error>) {
        guard let continuation else { return }
        self.continuation = nil
        operationTask?.cancel()
        timerTask?.cancel()
        operationTask = nil
        timerTask = nil
        continuation.resume(with: result)
    }
}
