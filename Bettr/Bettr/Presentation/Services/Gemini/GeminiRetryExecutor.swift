import Foundation

nonisolated protocol GeminiSleeping: Sendable {
    nonisolated func sleep(for duration: TimeInterval) async throws
}

nonisolated struct TaskGeminiSleeper: GeminiSleeping {
    nonisolated func sleep(for duration: TimeInterval) async throws {
        guard duration > 0 else { return }

        try await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
    }
}

@MainActor
struct GeminiRetryExecutor {
    private let maximumAttempts: Int
    private let sleeper: any GeminiSleeping

    init(maximumAttempts: Int = 2, sleeper: any GeminiSleeping = TaskGeminiSleeper()) {
        self.maximumAttempts = max(1, maximumAttempts)
        self.sleeper = sleeper
    }

    func perform<Value>(_ operation: () async throws -> Value) async throws -> Value {
        for attempt in 1...maximumAttempts {
            do {
                try Task.checkCancellation()
                let value = try await operation()
                try Task.checkCancellation()
                return value
            } catch {
                let aiError = retryError(from: error)

                guard let delay = retryDelay(for: aiError, attempt: attempt) else {
                    throw aiError
                }

                do {
                    try Task.checkCancellation()
                    try await sleeper.sleep(for: delay)
                    try Task.checkCancellation()
                } catch {
                    throw retryError(from: error)
                }
            }
        }

        throw AIError.unknown
    }

    private func retryError(from error: Error) -> AIError {
        if Task.isCancelled || error is CancellationError {
            return .cancelled
        }

        return (error as? AIError) ?? .unknown
    }

    private func retryDelay(for error: AIError, attempt: Int) -> TimeInterval? {
        guard attempt < maximumAttempts else { return nil }

        switch error {
        case .transient:
            return pow(2.0, Double(attempt - 1))
        case .responseContract:
            return 1
        case .cancelled, .authentication, .rateLimited, .invalidInput, .unknown:
            return nil
        }
    }
}
