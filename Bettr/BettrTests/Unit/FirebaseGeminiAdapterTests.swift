import XCTest
@testable import Bettr

@MainActor
final class FirebaseGeminiAdapterTests: XCTestCase {
    func test_analyze_whenStubReturnsValidJSON_thenReturnsValidatedDTO() async throws {
        let stub = TextStub(responses: [.success(Self.scriptJSON)])
        let adapter = makeAdapter(stub)
        let result = try await adapter.analyzeScript("Hello world.")
        XCTAssertEqual(result.title, "Title")
        XCTAssertEqual(result.sentences.first?.englishText, "Hello world.")
        XCTAssertEqual(stub.prompts.count, 1)
        XCTAssertTrue(stub.prompts[0].contains("Hello world."))
    }

    func test_extract_whenStubReturnsValidJSON_thenReturnsWordData() async throws {
        let stub = TextStub(responses: [.success(Self.wordJSON)])
        let words = try await makeAdapter(stub).extractWords(from: "An enormous challenge.")
        XCTAssertEqual(words, [WordData(lemma: "challenge", pos: "명", meaning: "도전")])
        XCTAssertEqual(stub.prompts.count, 1)
    }

    func test_analyze_whenResponseOmitsSource_thenRetriesAndThrowsContractError() async {
        let stub = TextStub(responses: [.success(Self.scriptJSON), .success(Self.scriptJSON)])
        await assertFailure(.responseContract) {
            _ = try await self.makeAdapter(stub).analyzeScript("Hello world. Goodbye.")
        }
        XCTAssertEqual(stub.prompts.count, 2)
    }

    func test_extract_whenTransientFailureThenSuccess_thenRetriesOnlyRequest() async throws {
        let stub = TextStub(responses: [.failure(AIError.transient), .success(Self.wordJSON)])
        let words = try await makeAdapter(stub).extractWords(from: "A challenge.")
        XCTAssertEqual(words.count, 1)
        XCTAssertEqual(stub.prompts.count, 2)
    }

    func test_extract_whenEmptyResponse_thenThrowsAfterTwoAttempts() async {
        let stub = TextStub(responses: [.success("[]"), .success("[]")])
        await assertFailure(.responseContract) {
            _ = try await self.makeAdapter(stub).extractWords(from: "A challenge.")
        }
        XCTAssertEqual(stub.prompts.count, 2)
    }

    func test_calls_whenTerminalFailure_thenDoesNotRetry() async {
        for failure in [AIError.authentication, .rateLimited, .invalidInput, .unknown, .cancelled] {
            let stub = TextStub(responses: [.failure(failure)])
            await assertFailure(failure) {
                _ = try await self.makeAdapter(stub).analyzeScript("Hello world.")
            }
            XCTAssertEqual(stub.prompts.count, 1)
        }
    }

    func test_calls_whenInputBlank_thenDoesNotCallProvider() async {
        let stub = TextStub(responses: [])
        let adapter = makeAdapter(stub)
        await assertFailure(.invalidInput) { _ = try await adapter.analyzeScript(" \n") }
        await assertFailure(.invalidInput) { _ = try await adapter.extractWords(from: " \n") }
        XCTAssertTrue(stub.prompts.isEmpty)
    }

    func test_extract_whenCancelledProviderReturnsLateSuccess_thenDiscardsIt() async {
        let stub = TextStub(responses: [.success(Self.wordJSON)])
        stub.beforeReturn = { withUnsafeCurrentTask { $0?.cancel() } }
        let adapter = makeAdapter(stub)
        let task = Task { try await adapter.extractWords(from: "A challenge.") }
        await assertFailure(.cancelled) { _ = try await task.value }
        XCTAssertEqual(stub.prompts.count, 1)
    }

    private func makeAdapter(_ stub: TextStub) -> FirebaseGeminiAdapter {
        FirebaseGeminiAdapter(
            generateText: stub.generate,
            retryExecutor: GeminiRetryExecutor(sleeper: ImmediateSleeper())
        )
    }

    private func assertFailure(_ expected: AIError, operation: () async throws -> Void) async {
        do {
            try await operation()
            XCTFail("Expected failure")
        } catch {
            XCTAssertEqual(error as? AIError, expected)
        }
    }

    private static let scriptJSON = """
    {"title":"Title","sentences":[{
      "orderIndex":0,"englishText":"Hello world.","koreanText":"안녕 세상.",
      "chunks":[{"orderIndex":0,"englishText":"Hello world.","koreanText":"안녕 세상."}]
    }]}
    """
    private static let wordJSON = #"[{"lemma":"challenge","pos":"명","meaning":"도전"}]"#
}

@MainActor
private final class TextStub {
    var responses: [Result<String, Error>]
    var prompts: [String] = []
    var beforeReturn: (() -> Void)?

    init(responses: [Result<String, Error>]) { self.responses = responses }

    func generate(_ prompt: String) async throws -> String {
        prompts.append(prompt)
        beforeReturn?()
        guard !responses.isEmpty else { throw AIError.unknown }
        return try responses.removeFirst().get()
    }
}

private actor ImmediateSleeper: GeminiSleeping {
    func sleep(for duration: TimeInterval) {}
}
