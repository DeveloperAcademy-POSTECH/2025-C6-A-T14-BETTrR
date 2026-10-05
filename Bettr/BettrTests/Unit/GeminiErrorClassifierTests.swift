import Foundation
import FirebaseAILogic
import XCTest
@testable import Bettr

@MainActor
final class GeminiErrorClassifierTests: XCTestCase {
    func test_classify_whenBackendHTTPError_thenReturnsTypedFailure() {
        let cases: [(Int, AIError)] = [
            (400, .invalidInput), (401, .authentication), (403, .authentication),
            (404, .invalidInput), (408, .transient), (413, .invalidInput),
            (422, .invalidInput), (429, .rateLimited), (499, .cancelled),
            (500, .transient), (503, .transient), (504, .transient), (418, .unknown)
        ]
        for (code, expected) in cases {
            let underlying = NSError(domain: "com.google.firebase.firebaseai.BackendError", code: code)
            XCTAssertEqual(classifyGeminiCallError(GenerateContentError.internalError(underlying: underlying)), expected)
        }
    }

    func test_classify_whenCancelledOrNetworkFailure_thenPreservesCategory() {
        XCTAssertEqual(classifyGeminiCallError(CancellationError()), .cancelled)
        XCTAssertEqual(classifyGeminiCallError(URLError(.cancelled)), .cancelled)
        XCTAssertEqual(classifyGeminiCallError(URLError(.timedOut)), .transient)
        XCTAssertEqual(classifyGeminiCallError(URLError(.notConnectedToInternet)), .transient)
        XCTAssertEqual(classifyGeminiCallError(URLError(.cannotParseResponse)), .responseContract)
        XCTAssertEqual(classifyGeminiCallError(AIError.rateLimited), .rateLimited)
    }

    func test_classify_whenUnrelatedErrorContainsStatusOrProviderMessage_thenReturnsUnknown() {
        let error = NSError(domain: "SQLite", code: 429, userInfo: [NSLocalizedDescriptionKey: "quota unauthenticated"])
        XCTAssertEqual(classifyGeminiCallError(error), .unknown)
    }

    func test_classify_whenNestedDecodingFails_thenReturnsResponseContract() {
        let error = DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Invalid JSON"))
        XCTAssertEqual(classifyGeminiCallError(GenerateContentError.internalError(underlying: error)), .responseContract)
    }
}
