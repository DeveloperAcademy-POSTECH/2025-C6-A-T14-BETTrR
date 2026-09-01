import Foundation
import XCTest
@testable import Bettr

final class GeminiErrorClassifierTests: XCTestCase {
    func test_classify_whenPermissionDeniedMessage_thenReturnsAuth() {
        let error = NSError(
            domain: "Firebase",
            code: 0,
            userInfo: [NSLocalizedDescriptionKey: "PERMISSION_DENIED"]
        )

        XCTAssertEqual(classifyGeminiCallError(error), .auth)
    }

    func test_classify_whenResourceExhaustedMessage_thenReturnsRateLimited() {
        let error = NSError(
            domain: "Firebase",
            code: 0,
            userInfo: [NSLocalizedDescriptionKey: "RESOURCE_EXHAUSTED"]
        )

        XCTAssertEqual(classifyGeminiCallError(error), .rateLimited)
    }

    func test_classify_whenNetworkTimeout_thenReturnsTransient() {
        XCTAssertEqual(classifyGeminiCallError(URLError(.timedOut)), .transient)
    }

    func test_classify_whenResponseCannotBeParsed_thenReturnsJSONParsing() {
        XCTAssertEqual(classifyGeminiCallError(URLError(.cannotParseResponse)), .jsonParsing)
    }

    func test_classify_whenHTTPClientError_thenReturnsClientInput() {
        XCTAssertEqual(classifyGeminiCallError(NSError(domain: "HTTP", code: 400)), .clientInput)
    }
}
