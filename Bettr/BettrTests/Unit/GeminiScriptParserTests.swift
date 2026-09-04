import XCTest
@testable import Bettr

final class GeminiScriptParserTests: XCTestCase {
    func test_parse_whenValidJSON_thenPreservesTitleAndOrderIndexes() {
        let scriptData = parseGeminiJSONToScriptData(validJSON, fallbackTitle: "Fallback")

        XCTAssertEqual(scriptData?.title, "Generated title")
        XCTAssertEqual(scriptData?.sentences.map(\.orderIndex), [0, 1])
        XCTAssertEqual(scriptData?.sentences[0].chunks.map(\.orderIndex), [0, 1])
    }

    func test_parse_whenJSONIsWrappedInCodeFence_thenDecodesScriptData() {
        let scriptData = parseGeminiJSONToScriptData("```json\n\(validJSON)\n```", fallbackTitle: "Fallback")

        XCTAssertEqual(scriptData?.sentences.count, 2)
    }

    func test_parse_whenTitleIsEmpty_thenUsesFallbackTitle() {
        let scriptData = parseGeminiJSONToScriptData(
            validJSON.replacingOccurrences(of: "Generated title", with: ""),
            fallbackTitle: "Fallback"
        )

        XCTAssertEqual(scriptData?.title, "Fallback")
    }

    func test_parse_whenRequiredFieldIsMissing_thenReturnsNil() {
        let json = """
        {"title":"Title","sentences":[{"orderIndex":0,"englishText":"Hello","chunks":[]}]}
        """

        XCTAssertNil(parseGeminiJSONToScriptData(json, fallbackTitle: "Fallback"))
    }

    func test_parse_whenResponseIsEmpty_thenReturnsNil() {
        XCTAssertNil(parseGeminiJSONToScriptData("  \n", fallbackTitle: "Fallback"))
    }

    private let validJSON = """
    {
      "title": "Generated title",
      "sentences": [
        {
          "orderIndex": 0,
          "englishText": "Hello world.",
          "koreanText": "안녕 세상.",
          "chunks": [
            { "orderIndex": 0, "englishText": "Hello", "koreanText": "안녕" },
            { "orderIndex": 1, "englishText": "world.", "koreanText": "세상." }
          ]
        },
        {
          "orderIndex": 1,
          "englishText": "Goodbye.",
          "koreanText": "안녕히 가세요.",
          "chunks": []
        }
      ]
    }
    """
}
