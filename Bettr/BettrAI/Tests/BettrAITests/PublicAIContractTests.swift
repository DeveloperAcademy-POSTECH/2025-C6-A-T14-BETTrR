import Foundation
import XCTest
import BettrAI

final class PublicAIContractTests: XCTestCase {
    func test_valuesCanCrossActorBoundaryAndRoundTripWithoutAppModels() async throws {
        let chunk = ChunkData(orderIndex: 0, englishText: "Hello", koreanText: "안녕")
        let sentence = SentenceData(
            orderIndex: 0, englishText: "Hello", koreanText: "안녕", chunks: [chunk]
        )
        let script = ScriptData(title: "Greeting", sentences: [sentence])
        let word = WordData(lemma: "hello", pos: "interjection", meaning: "안녕")

        let result = try await Task.detached {
            let encoded = try JSONEncoder().encode(script)
            let decoded = try JSONDecoder().decode(ScriptData.self, from: encoded)
            return (decoded, word)
        }.value

        XCTAssertEqual(result.0, script)
        XCTAssertEqual(result.1, word)
    }

    @MainActor
    func test_publicAdapterRejectsEmptyInputWithoutFirebaseBootstrap() async {
        let adapter = FirebaseGeminiAdapter()
        let analyzer: any ScriptAnalyzing = adapter
        let extractor: any WordExtracting = adapter
        do {
            _ = try await analyzer.analyzeScript(" \n")
            XCTFail("Expected invalid input")
        } catch {
            XCTAssertEqual(error as? AIError, .invalidInput)
        }
        do {
            _ = try await extractor.extractWords(from: "\t")
            XCTFail("Expected invalid input")
        } catch {
            XCTAssertEqual(error as? AIError, .invalidInput)
        }
    }
}
