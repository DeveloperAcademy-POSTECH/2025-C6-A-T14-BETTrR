import Foundation
import XCTest
@testable import Bettr

final class GeminiWordTests: XCTestCase {
    func test_decode_whenAllRequiredFieldsExist_thenCreatesGeminiWord() throws {
        let data = #"{"lemma":"encounter","pos":"동","meaning":"마주치다"}"#.data(using: .utf8)!

        let word = try JSONDecoder().decode(GeminiWord.self, from: data)

        XCTAssertEqual(word.lemma, "encounter")
        XCTAssertEqual(word.pos, "동")
        XCTAssertEqual(word.meaning, "마주치다")
    }

    func test_decode_whenRequiredFieldIsMissing_thenThrowsDecodingError() {
        let data = #"{"lemma":"encounter","pos":"동"}"#.data(using: .utf8)!

        XCTAssertThrowsError(try JSONDecoder().decode(GeminiWord.self, from: data))
    }
}
