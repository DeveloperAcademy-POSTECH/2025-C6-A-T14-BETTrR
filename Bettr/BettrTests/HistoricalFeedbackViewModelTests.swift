import XCTest
import GRDB
import Speech
@testable import Bettr

final class HistoricalFeedbackViewModelTests: XCTestCase {
    var scriptManagementService: MockScriptManagementService!
    var dbQueue: DatabaseQueue!
    
    override func setUp() {
        super.setUp()
        dbQueue = try! DatabaseQueue()
        try! DatabaseMigrator.setupDatabase(dbQueue)
        scriptManagementService = MockScriptManagementService(dbQueue: dbQueue)
    }
    
    override func tearDown() {
        scriptManagementService = nil
        dbQueue = nil
        super.tearDown()
    }
    
    // MARK: - Helpers
    
    private func createDummyScript(title: String, sentences: [String]) throws -> Script {
        var script = Script(title: title, createdAt: Date(), lastViewedAt: Date())
        script = try scriptManagementService.scriptRepository.save(script: &script)
        
        for (index, text) in sentences.enumerated() {
            var sentence = Sentence(
                scriptId: script.id!,
                orderIndex: index,
                englishText: text,
                koreanText: "Dummy Korean"
            )
            _ = try scriptManagementService.scriptRepository.save(sentence: &sentence)
        }
        return script
    }
    
    // MARK: - Tests
    
    func testHistoricalFeedback_MatchesCurrentFeedback_WithExtraWord() async throws {
        // Given: Script and feedback with extra word
        let sentences = ["Hello world.", "How are you?"]
        let script = try createDummyScript(title: "Test Script", sentences: sentences)
        
        // Original words: hello, world, how, are, you = 5 words
        // Spoken words: hello, extra, world, how, are, you = 6 words (1 extra)
        // Matched: hello, world, how, are, you = 5 words
        // Accuracy: 5/5 = 1.0 (all original words matched)
        let feedbackResult = FeedbackResultModel(
            diffs: [
                .matched(word: "hello"),
                .extra(actual: "extra"),
                .matched(word: "world"),
                .matched(word: "how"),
                .matched(word: "are"),
                .matched(word: "you")
            ],
            accuracy: 1.0,
            totalOriginalWords: 5,
            totalRecordingTime: 10.0
        )
        
        // When: Create current feedback
        let currentViewModel = await MainActor.run {
            FeedbackViewModel(
                scriptId: script.id!,
                feedbackResult: feedbackResult,
                sentences: sentences,
                scriptManagementService: scriptManagementService
            )
        }
        
        // Get error counts from MainActor context
        let (missingCount, extraCount, replacedCount) = await MainActor.run {
            (currentViewModel.missingCount, currentViewModel.extraCount, currentViewModel.replacedCount)
        }
        
        // Save to database
        let detailsData = extractDetailsData(from: feedbackResult)
        let summary = try scriptManagementService.scriptRepository.createFeedbackSummaryWithDetails(
            scriptId: script.id!,
            totalScore: feedbackResult.accuracy,
            missingWordCount: missingCount,
            addedWordCount: extraCount,
            replacedWordCount: replacedCount,
            practiceDuration: feedbackResult.totalRecordingTime,
            feedbackDetailsData: detailsData
        )
        
        // Load historical feedback
        let historicalViewModel = await MainActor.run {
            HistoricalFeedbackViewModel(
                summary: summary,
                scriptManagementService: scriptManagementService
            )
        }
        
        // Then: Verify they match
        await MainActor.run {
            let currentData = currentViewModel.filteredSentenceDiffs.map { $0.data }
            let historicalData = historicalViewModel.filteredSentenceDiffs.map { $0.data }
            
            XCTAssertEqual(currentData.count, historicalData.count, "Sentence count should match")
            
            for i in 0..<currentData.count {
                XCTAssertEqual(
                    currentData[i].original,
                    historicalData[i].original,
                    "Sentence \(i): original text should match"
                )
                XCTAssertEqual(
                    currentData[i].diffs,
                    historicalData[i].diffs,
                    "Sentence \(i): diffs should match"
                )
            }
            
            XCTAssertEqual(currentViewModel.extraCount, historicalViewModel.extraCount, "Extra count should match")
            XCTAssertEqual(currentViewModel.missingCount, historicalViewModel.missingCount, "Missing count should match")
            XCTAssertEqual(currentViewModel.replacedCount, historicalViewModel.replacedCount, "Replaced count should match")
        }
    }
    
    func testHistoricalFeedback_MatchesCurrentFeedback_WithMissingWord() async throws {
        // Given: Script and feedback with missing word
        let sentences = ["Hello world everyone."]
        let script = try createDummyScript(title: "Test Script", sentences: sentences)
        
        // Original words: hello, world, everyone = 3 words
        // Spoken words: hello, everyone = 2 words (1 missing)
        // Matched: hello, everyone = 2 words
        // Accuracy: 2/3 = 0.666...
        let feedbackResult = FeedbackResultModel(
            diffs: [
                .matched(word: "hello"),
                .missing(expected: "world"),
                .matched(word: "everyone")
            ],
            accuracy: 2.0 / 3.0,
            totalOriginalWords: 3,
            totalRecordingTime: 5.0
        )
        
        // When: Create current feedback
        let currentViewModel = await MainActor.run {
            FeedbackViewModel(
                scriptId: script.id!,
                feedbackResult: feedbackResult,
                sentences: sentences,
                scriptManagementService: scriptManagementService
            )
        }
        
        let (missingCount, extraCount, replacedCount) = await MainActor.run {
            (currentViewModel.missingCount, currentViewModel.extraCount, currentViewModel.replacedCount)
        }
        
        // Save to database
        let detailsData = extractDetailsData(from: feedbackResult)
        let summary = try scriptManagementService.scriptRepository.createFeedbackSummaryWithDetails(
            scriptId: script.id!,
            totalScore: feedbackResult.accuracy,
            missingWordCount: missingCount,
            addedWordCount: extraCount,
            replacedWordCount: replacedCount,
            practiceDuration: feedbackResult.totalRecordingTime,
            feedbackDetailsData: detailsData
        )
        
        // Load historical feedback
        let historicalViewModel = await MainActor.run {
            HistoricalFeedbackViewModel(
                summary: summary,
                scriptManagementService: scriptManagementService
            )
        }
        
        // Then: Verify they match
        await MainActor.run {
            let currentData = currentViewModel.filteredSentenceDiffs.map { $0.data }
            let historicalData = historicalViewModel.filteredSentenceDiffs.map { $0.data }
            
            XCTAssertEqual(currentData.count, historicalData.count)
            XCTAssertEqual(currentData[0].diffs, historicalData[0].diffs)
            XCTAssertEqual(currentViewModel.missingCount, historicalViewModel.missingCount)
        }
    }
    
    func testHistoricalFeedback_MatchesCurrentFeedback_WithReplacedWord() async throws {
        // Given: Script and feedback with replaced word
        let sentences = ["Hello world."]
        let script = try createDummyScript(title: "Test Script", sentences: sentences)
        
        // Original words: hello, world = 2 words
        // Spoken words: hello, earth = 2 words (1 replaced)
        // Matched: hello = 1 word
        // Accuracy: 1/2 = 0.5
        let feedbackResult = FeedbackResultModel(
            diffs: [
                .matched(word: "hello"),
                .replaced(expected: "world", actual: "earth")
            ],
            accuracy: 0.5,
            totalOriginalWords: 2,
            totalRecordingTime: 5.0
        )
        
        // When: Create current feedback
        let currentViewModel = await MainActor.run {
            FeedbackViewModel(
                scriptId: script.id!,
                feedbackResult: feedbackResult,
                sentences: sentences,
                scriptManagementService: scriptManagementService
            )
        }
        
        let (missingCount, extraCount, replacedCount) = await MainActor.run {
            (currentViewModel.missingCount, currentViewModel.extraCount, currentViewModel.replacedCount)
        }
        
        // Save to database
        let detailsData = extractDetailsData(from: feedbackResult)
        let summary = try scriptManagementService.scriptRepository.createFeedbackSummaryWithDetails(
            scriptId: script.id!,
            totalScore: feedbackResult.accuracy,
            missingWordCount: missingCount,
            addedWordCount: extraCount,
            replacedWordCount: replacedCount,
            practiceDuration: feedbackResult.totalRecordingTime,
            feedbackDetailsData: detailsData
        )
        
        // Load historical feedback
        let historicalViewModel = await MainActor.run {
            HistoricalFeedbackViewModel(
                summary: summary,
                scriptManagementService: scriptManagementService
            )
        }
        
        // Then: Verify they match
        await MainActor.run {
            let currentData = currentViewModel.filteredSentenceDiffs.map { $0.data }
            let historicalData = historicalViewModel.filteredSentenceDiffs.map { $0.data }
            
            XCTAssertEqual(currentData.count, historicalData.count)
            XCTAssertEqual(currentData[0].diffs, historicalData[0].diffs)
            XCTAssertEqual(currentViewModel.replacedCount, historicalViewModel.replacedCount)
        }
    }
    
    func testHistoricalFeedback_MatchesCurrentFeedback_WithMultipleErrors() async throws {
        // Given: Script and feedback with multiple error types
        let sentences = ["Hello beautiful world.", "How are you doing?"]
        let script = try createDummyScript(title: "Test Script", sentences: sentences)
        
        // Original words: hello, beautiful, world, how, are, you, doing = 7 words
        // Spoken words: hello, world, how, is, you = 5 words
        // Matched: hello, world, how, you = 4 words
        // Missing: beautiful, doing = 2 words
        // Replaced: are -> is = 1 word
        // Accuracy: 4/7 = 0.571...
        let feedbackResult = FeedbackResultModel(
            diffs: [
                .matched(word: "hello"),
                .missing(expected: "beautiful"),
                .matched(word: "world"),
                .matched(word: "how"),
                .replaced(expected: "are", actual: "is"),
                .matched(word: "you"),
                .missing(expected: "doing")
            ],
            accuracy: 4.0 / 7.0,
            totalOriginalWords: 7,
            totalRecordingTime: 12.0
        )
        
        // When: Create current feedback
        let currentViewModel = await MainActor.run {
            FeedbackViewModel(
                scriptId: script.id!,
                feedbackResult: feedbackResult,
                sentences: sentences,
                scriptManagementService: scriptManagementService
            )
        }
        
        let (missingCount, extraCount, replacedCount) = await MainActor.run {
            (currentViewModel.missingCount, currentViewModel.extraCount, currentViewModel.replacedCount)
        }
        
        // Save to database
        let detailsData = extractDetailsData(from: feedbackResult)
        let summary = try scriptManagementService.scriptRepository.createFeedbackSummaryWithDetails(
            scriptId: script.id!,
            totalScore: feedbackResult.accuracy,
            missingWordCount: missingCount,
            addedWordCount: extraCount,
            replacedWordCount: replacedCount,
            practiceDuration: feedbackResult.totalRecordingTime,
            feedbackDetailsData: detailsData
        )
        
        // Load historical feedback
        let historicalViewModel = await MainActor.run {
            HistoricalFeedbackViewModel(
                summary: summary,
                scriptManagementService: scriptManagementService
            )
        }
        
        // Then: Verify they match
        await MainActor.run {
            let currentData = currentViewModel.filteredSentenceDiffs.map { $0.data }
            let historicalData = historicalViewModel.filteredSentenceDiffs.map { $0.data }
            
            XCTAssertEqual(currentData.count, historicalData.count, "Sentence count should match")
            
            for i in 0..<currentData.count {
                XCTAssertEqual(currentData[i].diffs, historicalData[i].diffs, "Sentence \(i): diffs should match")
            }
            
            XCTAssertEqual(currentViewModel.extraCount, historicalViewModel.extraCount)
            XCTAssertEqual(currentViewModel.missingCount, historicalViewModel.missingCount)
            XCTAssertEqual(currentViewModel.replacedCount, historicalViewModel.replacedCount)
        }
    }
    
    // MARK: - Helper Methods
    
    private func extractDetailsData(from feedbackResult: FeedbackResultModel) -> [(
        errorType: FeedbackErrorType,
        originalText: String?,
        spokenText: String?,
        startTime: Double,
        endTime: Double
    )] {
        var data: [(FeedbackErrorType, String?, String?, Double, Double)] = []
        
        for diff in feedbackResult.diffs {
            switch diff {
            case .matched:
                break
            case .missing(let expected):
                data.append((.missingWord, expected, nil, 0.0, 0.0))
            case .extra(let actual):
                data.append((.addedWord, nil, actual, 0.0, 0.0))
            case .replaced(let expected, let actual):
                data.append((.replacedWord, expected, actual, 0.0, 0.0))
            }
        }
        
        return data
    }
}

// MARK: - Mock Service

class MockScriptManagementService: ScriptManagementServiceProtocol {
    let scriptRepository: ScriptRepository
    
    init(dbQueue: DatabaseQueue) {
        self.scriptRepository = ScriptRepository(dbQueue: dbQueue)
    }
    
    func fetchScriptWithSentencesAndChunks(id: Int64) throws -> (script: Script, sentences: [(sentence: Sentence, chunks: [Chunk])])? {
        guard let script = try scriptRepository.fetchScript(id: id) else { return nil }
        let sentences = try scriptRepository.fetchSentences(forScriptId: id)
        var sentencesWithChunks: [(sentence: Sentence, chunks: [Chunk])] = []
        for sentence in sentences {
            let chunks = try scriptRepository.fetchChunks(forSentenceId: sentence.id!)
            sentencesWithChunks.append((sentence: sentence, chunks: chunks))
        }
        return (script, sentencesWithChunks)
    }
    
    func fetchScriptWithSentences(id: Int64) throws -> (script: Script, sentences: [Sentence])? {
        guard let script = try scriptRepository.fetchScript(id: id) else { return nil }
        let sentences = try scriptRepository.fetchSentences(forScriptId: id)
        return (script, sentences)
    }
    
    func createFeedbackSummary(scriptId: Int64, totalScore: Double, missingWordCount: Int, addedWordCount: Int, replacedWordCount: Int, practiceDuration: Double, feedbackDetailsData: [(errorType: FeedbackErrorType, originalText: String?, spokenText: String?, startTime: Double, endTime: Double)]) throws -> FeedbackSummary {
        return try scriptRepository.createFeedbackSummaryWithDetails(
            scriptId: scriptId,
            totalScore: totalScore,
            missingWordCount: missingWordCount,
            addedWordCount: addedWordCount,
            replacedWordCount: replacedWordCount,
            practiceDuration: practiceDuration,
            feedbackDetailsData: feedbackDetailsData
        )
    }
    
    func fetchFeedbackSummaries(forScriptId: Int64) throws -> [FeedbackSummary] {
        return try scriptRepository.fetchFeedbackSummaries(forScriptId: forScriptId)
    }
    
    func fetchFeedbackDetails(forFeedbackSummaryId feedbackSummaryId: Int64) throws -> [FeedbackDetail] {
        return try scriptRepository.fetchFeedbackDetails(forFeedbackSummaryId: feedbackSummaryId)
    }
    
    func updateScriptTitle(scriptId: Int64, newTitle: String) throws {
        try scriptRepository.updateScriptTitle(id: scriptId, newTitle: newTitle)
    }
}
