import Foundation
import FirebaseAILogic

@MainActor
final class FirebaseGeminiAdapter: ScriptAnalyzing, WordExtracting {
    typealias GenerateText = @MainActor (String) async throws -> String

    private let generateText: GenerateText
    private let retryExecutor: GeminiRetryExecutor

    init(
        generateText: GenerateText? = nil,
        retryExecutor: GeminiRetryExecutor? = nil
    ) {
        self.generateText = generateText ?? FirebaseGeminiTextGenerator().generateText
        self.retryExecutor = retryExecutor ?? GeminiRetryExecutor()
    }

    func analyzeScript(_ content: String) async throws -> ScriptData {
        guard !Task.isCancelled else { throw AIError.cancelled }
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AIError.invalidInput
        }

        return try await retryExecutor.perform {
            guard !Task.isCancelled else { throw AIError.cancelled }
            let responseText = try await generateText(for: GeminiPromptBuilder.script(content: content))
            guard !Task.isCancelled else { throw AIError.cancelled }
            return try GeminiScriptParser.parse(
                responseText,
                sourceText: content,
                fallbackTitle: "사용자 입력 스크립트"
            )
        }
    }

    func extractWords(from content: String) async throws -> [WordData] {
        guard !Task.isCancelled else { throw AIError.cancelled }
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AIError.invalidInput
        }

        return try await retryExecutor.perform {
            guard !Task.isCancelled else { throw AIError.cancelled }
            let responseText = try await generateText(for: GeminiPromptBuilder.words(content: content))
            guard !Task.isCancelled else { throw AIError.cancelled }
            return try GeminiWordParser.parse(responseText)
        }
    }

    private func generateText(for prompt: String) async throws -> String {
        do {
            return try await generateText(prompt)
        } catch {
            if Task.isCancelled || error is CancellationError {
                throw AIError.cancelled
            }

            throw classifyGeminiCallError(error)
        }
    }
}

@MainActor
private final class FirebaseGeminiTextGenerator {
    private lazy var model = FirebaseAI
        .firebaseAI(backend: .googleAI(), useLimitedUseAppCheckTokens: true)
        .generativeModel(modelName: "gemini-2.5-flash-lite")

    func generateText(for prompt: String) async throws -> String {
        let response = try await model.generateContent(prompt)
        guard let text = response.text else {
            throw AIError.responseContract
        }

        return text
    }
}
