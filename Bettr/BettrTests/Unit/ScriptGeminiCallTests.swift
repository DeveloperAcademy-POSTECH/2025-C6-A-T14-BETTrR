import XCTest
@testable import Bettr

@MainActor
final class ScriptGeminiCallTests: XCTestCase {
    func test_analyze_whenFakeSucceeds_thenReturnsResultAndInput() async throws {
        let fake = FakeScriptAnalyzer()
        let client = ScriptGeminiCall(analyzer: fake)
        let result = try await client.analyzeScript("Hello.")

        XCTAssertEqual(result, fake.result)
        XCTAssertEqual(fake.inputs, ["Hello."])
    }

    func test_analyze_whenFakeFails_thenPreservesTypedFailure() async {
        let failures: [AIError] = [
            .authentication, .rateLimited, .transient, .invalidInput, .responseContract, .unknown, .cancelled
        ]
        for failure in failures {
            let fake = FakeScriptAnalyzer()
            fake.failure = failure
            do {
                _ = try await ScriptGeminiCall(analyzer: fake).analyzeScript("Hello.")
                XCTFail("Expected failure")
            } catch {
                XCTAssertEqual(error as? AIError, failure)
            }
            XCTAssertEqual(fake.inputs.count, 1)
        }
    }

    func test_analyze_whenCancelledBeforeCall_thenDoesNotStartProvider() async {
        let fake = FakeScriptAnalyzer()
        let client = ScriptGeminiCall(analyzer: fake)
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await client.analyzeScript("Hello.")
        }
        do {
            _ = try await task.value
            XCTFail("Expected cancellation")
        } catch {
            XCTAssertEqual(error as? AIError, .cancelled)
        }
        XCTAssertTrue(fake.inputs.isEmpty)
    }

    func test_analyze_whenProviderIgnoresCancellation_thenDiscardsLateSuccess() async {
        let fake = FakeScriptAnalyzer()
        fake.suspends = true
        let client = ScriptGeminiCall(analyzer: fake)
        let task = Task { try await client.analyzeScript("Hello.") }
        await fake.waitUntilStarted()
        task.cancel()
        fake.finish()

        do {
            _ = try await task.value
            XCTFail("Cancelled response must not reach persistence")
        } catch {
            XCTAssertEqual(error as? AIError, .cancelled)
        }
        XCTAssertEqual(fake.inputs.count, 1)
    }
}

@MainActor
private final class FakeScriptAnalyzer: ScriptAnalyzing {
    var inputs: [String] = []
    var failure: AIError?
    var suspends = false
    private var response: CheckedContinuation<ScriptData, Never>?
    private var started: CheckedContinuation<Void, Never>?
    let result = ScriptData(title: "Title", sentences: [
        SentenceData(orderIndex: 0, englishText: "Hello.", koreanText: "안녕.", chunks: [
            ChunkData(orderIndex: 0, englishText: "Hello.", koreanText: "안녕.")
        ])
    ])

    func analyzeScript(_ content: String) async throws -> ScriptData {
        inputs.append(content)
        if let failure { throw failure }
        if suspends {
            return await withCheckedContinuation { continuation in
                response = continuation
                started?.resume()
                started = nil
            }
        }
        return result
    }

    func waitUntilStarted() async {
        if response != nil { return }
        await withCheckedContinuation { started = $0 }
    }

    func finish() {
        response?.resume(returning: result)
        response = nil
    }
}
