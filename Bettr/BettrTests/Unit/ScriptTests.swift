import Foundation
import XCTest
@testable import Bettr

final class ScriptTests: XCTestCase {
    func test_markViewed_whenDateProvided_thenUpdatesLastViewedAt() {
        let createdAt = Date(timeIntervalSince1970: 0)
        let viewedAt = Date(timeIntervalSince1970: 1)
        var script = Script.from(
            ScriptData(title: "Title", sentences: []),
            createdAt: createdAt
        )

        script.markViewed(at: viewedAt)

        XCTAssertEqual(script.lastViewedAt, viewedAt)
    }
}
