import XCTest
@testable import Bettr

final class GeminiScriptParserTests: XCTestCase {
    func test_parse_whenValidJSON_thenPreservesTitleAndOrderIndexes() throws {
        let result = try parse(validJSON)
        XCTAssertEqual(result.title, "Generated title")
        XCTAssertEqual(result.sentences.map(\.orderIndex), [0, 1])
        XCTAssertEqual(result.sentences[0].chunks.map(\.orderIndex), [0, 1])
    }

    func test_parse_whenFencedOrSourceWhitespaceDiffers_thenPreservesContent() throws {
        let result = try GeminiScriptParser.parse(
            "```json\n\(validJSON)\n```", sourceText: "Hello   world.\nGoodbye.", fallbackTitle: "Fallback"
        )
        XCTAssertEqual(result.sentences.map(\.englishText), ["Hello world.", "Goodbye."])
    }

    func test_parse_whenTitleEmpty_thenUsesFallback() throws {
        let json = try modified { $0.title = " \n" }
        XCTAssertEqual(try parse(json).title, "Fallback")
    }

    func test_parse_whenSourceBlank_thenThrowsInvalidInput() {
        XCTAssertThrowsError(try GeminiScriptParser.parse(validJSON, sourceText: " \n", fallbackTitle: "Fallback")) {
            XCTAssertEqual($0 as? AIError, .invalidInput)
        }
    }

    func test_parse_whenJSONMalformedOrRequiredFieldMissing_thenThrowsContractError() {
        for json in ["{", " \n", #"{"title":"Title","sentences":[{"orderIndex":0,"englishText":"Hello"}]}"#] {
            assertContractFailure(json)
        }
    }

    func test_parse_whenSentencesOrChunksEmpty_thenThrowsContractError() throws {
        assertContractFailure(try modified { $0.sentences = [] })
        assertContractFailure(try modified { $0.sentences[0].chunks = [] })
    }

    func test_parse_whenRequiredTextBlank_thenThrowsContractError() throws {
        assertContractFailure(try modified { $0.sentences[0].englishText = "" })
        assertContractFailure(try modified { $0.sentences[0].koreanText = " \n" })
        assertContractFailure(try modified { $0.sentences[0].chunks[0].englishText = "" })
        assertContractFailure(try modified { $0.sentences[0].chunks[0].koreanText = " " })
    }

    func test_parse_whenIndexesGappedDuplicatedOrReordered_thenThrowsContractError() throws {
        assertContractFailure(try modified { $0.sentences[1].orderIndex = 2 })
        assertContractFailure(try modified { $0.sentences[0].orderIndex = -1 })
        assertContractFailure(try modified { $0.sentences.reverse() })
        assertContractFailure(try modified { $0.sentences[0].chunks[1].orderIndex = 0 })
        assertContractFailure(try modified { $0.sentences[0].chunks[1].orderIndex = 2 })
    }

    func test_parse_whenSourceWordsOmittedAddedReorderedOrPunctuationChanged_thenThrowsContractError() {
        // Each response has valid sentence/chunk coverage; only input coverage differs.
        for source in ["Hello world. Goodbye. Again.", "Hello world.", "Goodbye. Hello world.", "Hello world! Goodbye."] {
            XCTAssertThrowsError(try GeminiScriptParser.parse(validJSON, sourceText: source, fallbackTitle: "Fallback")) {
                XCTAssertEqual($0 as? AIError, .responseContract)
            }
        }
    }

    func test_parse_whenChunksOmitAddReorderOrChangePunctuation_thenThrowsContractError() throws {
        assertContractFailure(try modified { $0.sentences[0].chunks[1].englishText = "earth." })
        assertContractFailure(try modified { $0.sentences[0].chunks[1].englishText = "world. Again." })
        assertContractFailure(try modified {
            $0.sentences[0].chunks[0].englishText = "world."
            $0.sentences[0].chunks[1].englishText = "Hello"
        })
        assertContractFailure(try modified { $0.sentences[0].chunks[1].englishText = "world" })
    }

    func test_parse_whenOCRContainsHeadingAndUnfinishedSentence_thenPreservesBothVerbatim() throws {
        let texts = ["LEARNING ENGLISH", "Hello world.", "When I started learning"]
        let response = ScriptData(title: "Learning English", sentences: texts.enumerated().map { index, text in
            SentenceData(orderIndex: index, englishText: text, koreanText: "번역", chunks: [
                ChunkData(orderIndex: 0, englishText: text, koreanText: "번역")
            ])
        })
        let json = String(decoding: try JSONEncoder().encode(response), as: UTF8.self)

        let result = try GeminiScriptParser.parse(
            json, sourceText: texts.joined(separator: "\n"), fallbackTitle: "Fallback"
        )

        XCTAssertEqual(result.sentences.map(\.englishText), texts)
    }

    func test_parse_whenOCRHeadingAppearsOnlyInTitle_thenRejectsOmittedSource() throws {
        let json = try modified { $0.title = "LEARNING ENGLISH" }

        XCTAssertThrowsError(try GeminiScriptParser.parse(
            json, sourceText: "LEARNING ENGLISH\nHello world.\nGoodbye.", fallbackTitle: "Fallback"
        )) {
            XCTAssertEqual($0 as? AIError, .responseContract)
        }
    }

    private func parse(_ json: String) throws -> ScriptData {
        try GeminiScriptParser.parse(json, sourceText: "Hello world. Goodbye.", fallbackTitle: "Fallback")
    }

    private func modified(_ modify: (inout ScriptData) -> Void) throws -> String {
        var fixture = try JSONDecoder().decode(ScriptData.self, from: Data(validJSON.utf8))
        modify(&fixture)
        return String(decoding: try JSONEncoder().encode(fixture), as: UTF8.self)
    }

    private func assertContractFailure(_ json: String, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertThrowsError(try parse(json), file: file, line: line) {
            XCTAssertEqual($0 as? AIError, .responseContract, file: file, line: line)
        }
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
          "chunks": [{ "orderIndex": 0, "englishText": "Goodbye.", "koreanText": "안녕히 가세요." }]
        }
      ]
    }
    """
}
