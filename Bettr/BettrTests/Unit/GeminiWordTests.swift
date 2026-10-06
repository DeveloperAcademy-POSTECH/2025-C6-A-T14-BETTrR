import XCTest
@testable import Bettr

final class GeminiWordTests: XCTestCase {
    func test_decode_whenAllRequiredFieldsExist_thenCreatesWordData() throws {
        let data = #"{"lemma":"encounter","pos":"동","meaning":"마주치다"}"#.data(using: .utf8)!

        let word = try JSONDecoder().decode(WordData.self, from: data)

        XCTAssertEqual(word.lemma, "encounter")
        XCTAssertEqual(word.pos, "동")
        XCTAssertEqual(word.meaning, "마주치다")
    }

    func test_decode_whenRequiredFieldIsMissing_thenThrowsDecodingError() {
        let data = #"{"lemma":"encounter","pos":"동"}"#.data(using: .utf8)!

        XCTAssertThrowsError(try JSONDecoder().decode(WordData.self, from: data))
    }

    func test_parse_whenValidJSON_thenReturnsWords() throws {
        let words = try GeminiWordParser.parse(validJSON)

        XCTAssertEqual(words.map(\.lemma), ["encounter", "challenge"])
        XCTAssertEqual(words.map(\.pos), ["동", "명"])
    }

    func test_parse_whenJSONIsWrappedInCodeFence_thenReturnsWords() throws {
        let words = try GeminiWordParser.parse("```json\n\(validJSON)\n```")

        XCTAssertEqual(words.count, 2)
    }

    func test_parse_whenResponseIsMalformedJSON_thenThrowsResponseContract() {
        assertThrowsAIError(.responseContract) {
            _ = try GeminiWordParser.parse("{")
        }
    }

    func test_parse_whenArrayIsEmpty_thenThrowsResponseContract() {
        assertThrowsAIError(.responseContract) {
            _ = try GeminiWordParser.parse("[]")
        }
    }

    func test_parse_whenFieldIsEmpty_thenThrowsResponseContract() {
        let json = #"[{"lemma":"","pos":"동","meaning":"마주치다"}]"#

        assertThrowsAIError(.responseContract) {
            _ = try GeminiWordParser.parse(json)
        }
    }

    func test_parse_whenPartOfSpeechIsUnknown_thenThrowsResponseContract() {
        let json = #"[{"lemma":"encounter","pos":"관형","meaning":"마주치다"}]"#

        assertThrowsAIError(.responseContract) {
            _ = try GeminiWordParser.parse(json)
        }
    }

    func test_parse_whenLemmaDoesNotAppearInSourceLikeInflection_thenStillAccepts() throws {
        let json = #"[{"lemma":"encounter","pos":"동","meaning":"마주치다"}]"#

        let words = try GeminiWordParser.parse(json)

        XCTAssertEqual(words.first?.lemma, "encounter")
    }

    private func assertThrowsAIError(
        _ expectedError: AIError,
        file: StaticString = #filePath,
        line: UInt = #line,
        _ expression: () throws -> Void
    ) {
        XCTAssertThrowsError(try expression(), file: file, line: line) { error in
            XCTAssertEqual(error as? AIError, expectedError, file: file, line: line)
        }
    }

    private let validJSON = """
    [
      {"lemma":"encounter","pos":"동","meaning":"마주치다"},
      {"lemma":"challenge","pos":"명","meaning":"도전"}
    ]
    """
}
