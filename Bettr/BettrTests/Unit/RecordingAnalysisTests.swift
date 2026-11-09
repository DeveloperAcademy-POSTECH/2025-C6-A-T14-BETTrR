import XCTest
@testable import Bettr

/// 녹음 평가의 정상 흐름(인식 텍스트 → 단어 비교 → 저장용 통계) 회귀 테스트입니다.
/// 상태 전이를 분리하는 리팩터링 전후로 같은 결과를 보장합니다.
final class RecordingAnalysisTests: XCTestCase {
    private let analyzer = SpeechAnalyzer()
    private lazy var processor = RecordingProcessor(analyzer: analyzer)

    func test_exactRecitationMatchesEveryWord() {
        let diffs = analyzer.analyze(reference: "Hello world. Nice day!", recognizedText: "hello world nice day")

        XCTAssertEqual(diffs, [
            .matched(word: "hello"), .matched(word: "world"),
            .matched(word: "nice"), .matched(word: "day")
        ])
    }

    func test_missingReplacedAndExtraWordsAreClassified() {
        let diffs = analyzer.analyze(
            reference: "I like green apples",
            recognizedText: "I like red apples really"
        )

        XCTAssertEqual(diffs, [
            .matched(word: "i"), .matched(word: "like"),
            .replaced(expected: "green", actual: "red"),
            .matched(word: "apples"), .extra(actual: "really")
        ])
    }

    func test_contractionsAreComparedAsExpandedWords() {
        let diffs = analyzer.analyze(reference: "I'm happy", recognizedText: "I am happy")

        XCTAssertEqual(diffs, [.matched(word: "i"), .matched(word: "am"), .matched(word: "happy")])
    }

    func test_emptyRecognitionProducesNoDiffs() {
        XCTAssertTrue(analyzer.analyze(reference: "Hello world", recognizedText: "").isEmpty)
        XCTAssertTrue(analyzer.analyze(reference: "", recognizedText: "hello").isEmpty)
    }

    func test_unrelatedRecognitionMarksUnreadScriptAsMissing() {
        let diffs = analyzer.analyze(reference: "alpha beta", recognizedText: "zzz")

        XCTAssertFalse(diffs.isEmpty)
        XCTAssertFalse(diffs.contains { if case .matched = $0 { true } else { false } })
    }

    func test_summaryStatsCountErrorsAndAccuracyAcrossSentences() {
        let sentences = ["I like green apples.", "See you."]
        let diffs = analyzer.analyze(
            reference: sentences.joined(separator: " "),
            recognizedText: "I like red apples see you"
        )

        let stats = processor.createSummaryStats(
            fromLiveAnalysis: diffs, sentences: sentences, practiceDuration: 12.5
        )

        XCTAssertEqual(stats.replacedCount, 1)
        XCTAssertEqual(stats.missingCount, 0)
        XCTAssertEqual(stats.extraCount, 0)
        XCTAssertEqual(stats.accuracy, 5.0 / 6.0, accuracy: 1e-9)
        XCTAssertEqual(stats.practiceDuration, 12.5)
        XCTAssertEqual(stats.dbDetails.map(\.sentenceIndex), [0, 0, 0, 0, 1, 1])
        XCTAssertEqual(stats.dbDetails.map(\.wordIndex), [0, 1, 2, 3, 0, 1])
        XCTAssertEqual(stats.dbDetails[2].originalText, "green")
    }

    func test_extraWordsAfterASentenceStayWithThatSentence() {
        let sentences = ["Hello world.", "Bye."]
        let diffs: [WordDiff] = [
            .matched(word: "hello"), .matched(word: "world"), .extra(actual: "uh"), .matched(word: "bye")
        ]

        let stats = processor.createSummaryStats(
            fromLiveAnalysis: diffs, sentences: sentences, practiceDuration: 1
        )

        XCTAssertEqual(stats.extraCount, 1)
        XCTAssertEqual(stats.dbDetails.map(\.sentenceIndex), [0, 0, 0, 1])
        XCTAssertNil(stats.dbDetails[2].originalText)
    }
}
