import Foundation

/// Feature boundary: a provider that finishes late must not publish a cancelled result.
@MainActor
final class ScriptGeminiCall: ScriptAnalyzing {
    private let analyzer: any ScriptAnalyzing

    init(analyzer: any ScriptAnalyzing) {
        self.analyzer = analyzer
    }

    func analyzeScript(_ content: String) async throws -> ScriptData {
        guard !Task.isCancelled else { throw AIError.cancelled }
        do {
            let result = try await analyzer.analyzeScript(content)
            guard !Task.isCancelled else { throw AIError.cancelled }
            return result
        } catch {
            if Task.isCancelled || error is CancellationError { throw AIError.cancelled }
            throw error
        }
    }
}
