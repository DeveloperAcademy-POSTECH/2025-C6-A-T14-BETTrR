//
//  GeminiScriptParser.swift
//  Bettr
//
//  Created by 서세린 on 11/5/25.
//

import Foundation

nonisolated enum GeminiScriptParser {
    static func parse(_ text: String, sourceText: String, fallbackTitle: String) throws -> ScriptData {
        let normalizedSource = normalizeWhitespace(sourceText)
        guard !normalizedSource.isEmpty else {
            throw AIError.invalidInput
        }

        let cleanedText = stripCodeFence(text)
        guard let data = cleanedText.data(using: .utf8) else {
            throw AIError.responseContract
        }

        let decoded: ScriptData
        do {
            decoded = try JSONDecoder().decode(ScriptData.self, from: data)
        } catch {
            throw AIError.responseContract
        }

        let finalTitle = decoded.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? fallbackTitle
            : decoded.title
        let scriptData = ScriptData(title: finalTitle, sentences: decoded.sentences)

        try validate(scriptData, normalizedSource: normalizedSource)
        return scriptData
    }

    private static func validate(_ scriptData: ScriptData, normalizedSource: String) throws {
        guard !scriptData.sentences.isEmpty else {
            throw AIError.responseContract
        }

        try validateOrderIndexes(scriptData.sentences.map(\.orderIndex))

        for sentence in scriptData.sentences {
            guard !normalizeWhitespace(sentence.englishText).isEmpty,
                  !normalizeWhitespace(sentence.koreanText).isEmpty,
                  !sentence.chunks.isEmpty else {
                throw AIError.responseContract
            }

            try validateOrderIndexes(sentence.chunks.map(\.orderIndex))

            for chunk in sentence.chunks {
                guard !normalizeWhitespace(chunk.englishText).isEmpty,
                      !normalizeWhitespace(chunk.koreanText).isEmpty else {
                    throw AIError.responseContract
                }
            }

            let chunkText = sentence.chunks.map(\.englishText).joined(separator: " ")
            guard normalizeWhitespace(chunkText) == normalizeWhitespace(sentence.englishText) else {
                throw AIError.responseContract
            }
        }

        let sentenceText = scriptData.sentences.map(\.englishText).joined(separator: " ")
        guard normalizeWhitespace(sentenceText) == normalizedSource else {
            throw AIError.responseContract
        }
    }

    private static func validateOrderIndexes(_ indexes: [Int]) throws {
        guard indexes == Array(0..<indexes.count) else {
            throw AIError.responseContract
        }
    }

    private static func stripCodeFence(_ text: String) -> String {
        text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: #"^```(?:json)?\s*"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\s*```$"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func normalizeWhitespace(_ text: String) -> String {
        text
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }
}
