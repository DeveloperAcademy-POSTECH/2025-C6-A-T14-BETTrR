import Foundation

nonisolated enum GeminiWordParser {
    private static let allowedPartsOfSpeech: Set<String> = [
        "명",
        "동",
        "형",
        "부",
        "대명",
        "전",
        "접",
        "숙어"
    ]

    static func parse(_ text: String) throws -> [WordData] {
        let cleanedText = stripCodeFence(text)
        guard let data = cleanedText.data(using: .utf8) else {
            throw AIError.responseContract
        }

        let words: [WordData]
        do {
            words = try JSONDecoder().decode([WordData].self, from: data)
        } catch {
            throw AIError.responseContract
        }

        guard !words.isEmpty else {
            throw AIError.responseContract
        }

        for word in words {
            guard !word.lemma.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  !word.pos.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  !word.meaning.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  allowedPartsOfSpeech.contains(word.pos) else {
                throw AIError.responseContract
            }
        }

        return words
    }

    private static func stripCodeFence(_ text: String) -> String {
        text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: #"^```(?:json)?\s*"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\s*```$"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
