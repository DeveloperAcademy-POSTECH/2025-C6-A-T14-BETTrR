import Foundation

protocol GeminiSleeping {
    func sleep(for duration: TimeInterval) async
}

struct TaskGeminiSleeper: GeminiSleeping {
    func sleep(for duration: TimeInterval) async {
        guard duration > 0 else { return }

        try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
    }
}

struct GeminiRetryExecutor {
    private let maximumAttempts: Int
    private let sleeper: any GeminiSleeping

    init(maximumAttempts: Int = 2, sleeper: any GeminiSleeping = TaskGeminiSleeper()) {
        self.maximumAttempts = maximumAttempts
        self.sleeper = sleeper
    }

    func perform<Value>(_ operation: () async throws -> Value) async -> Value? {
        for attempt in 1...maximumAttempts {
            do {
                return try await operation()
            } catch {
                guard let delay = retryDelay(for: error, attempt: attempt) else {
                    return nil
                }

                await sleeper.sleep(for: delay)
            }
        }

        return nil
    }

    private func retryDelay(for error: Error, attempt: Int) -> TimeInterval? {
        guard attempt < maximumAttempts else { return nil }

        switch classifyGeminiCallError(error) {
        case .transient:
            return pow(2.0, Double(attempt - 1))
        case .jsonParsing:
            return 1
        case .clientInput, .auth, .rateLimited, .unknown:
            return nil
        }
    }
}
