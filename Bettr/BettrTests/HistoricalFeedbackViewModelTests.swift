import XCTest
import GRDB
import Speech
@testable import Bettr

final class HistoricalFeedbackViewModelTests: XCTestCase {
    var scriptManagementService: ScriptManagementService!
    var dbQueue: DatabaseQueue!
    
    override func setUp() {
        super.setUp()
        dbQueue = try! DatabaseQueue(path: ":memory:") // Use in-memory database for tests
        try! DatabaseMigrator.setupDatabase(dbQueue)
        let scriptRepository = ScriptRepository(dbQueue: dbQueue) // Create a real ScriptRepository
        scriptManagementService = ScriptManagementService(scriptRepository: scriptRepository) // Pass it to the service
    }
    
    override func tearDown() {
        try! dbQueue.write { db in
            try Script.deleteAll(db)
            try Sentence.deleteAll(db)
            try Chunk.deleteAll(db)
            try FeedbackSummary.deleteAll(db)
            try FeedbackDetail.deleteAll(db)
        }
        scriptManagementService = nil
        dbQueue = nil
        super.tearDown()
    }
    
    // MARK: - Helpers
    
    private func createDummyScript(title: String, sentences: [String]) async throws -> Script { // Make it async
        let scriptData = ScriptData(
            title: title,
            sentences: sentences.enumerated().map { index, englishText in
                SentenceData(
                    orderIndex: index,
                    englishText: englishText,
                    koreanText: "Dummy Korean",
                    chunks: [ChunkData(orderIndex: 0, englishText: englishText, koreanText: "Dummy Korean")] // Add a dummy chunk
                )
            }
        )
        let script = try await scriptManagementService.createScript(scriptData: scriptData)
        return script
    }
    
    // MARK: - Tests
    
    func testHistoricalFeedback_MatchesCurrentFeedback_WithExtraWord() async throws {
        // Given: Script and feedback with extra word
        let sentences = ["Hello world.", "How are you?"] // Here, sentences is defined
        let script = try await createDummyScript(title: "Test Script", sentences: sentences)
        
        let diffs: [WordDiff] = [
            .matched(word: "hello"),
            .extra(actual: "extra"),
            .matched(word: "world"),
            .matched(word: "how"),
            .matched(word: "are"),
            .matched(word: "you")
        ]
        let accuracy: Double = 1.0
        let practiceDuration: Double = 10.0
        
        // When: Create current feedback
        let currentViewModel = await MainActor.run {
            FeedbackViewModel(
                scriptId: script.id!,
                diffs: diffs, // Pass diffs directly
                sentences: sentences, // sentences is used here
                practiceDuration: practiceDuration,
                scriptManagementService: scriptManagementService
            )
        }
        
        // Get error counts from MainActor context
        let (missingCount, extraCount, replacedCount) = await MainActor.run {
            (currentViewModel.missingCount, currentViewModel.extraCount, currentViewModel.replacedCount)
        }
        
        // Construct detailsData directly
        var detailsData: [(wordDiff: WordDiff, originalText: String?, sentenceIndex: Int, wordIndex: Int)] = []
        let analyzer = SpeechAnalyzer()
        var tempDiffs = diffs
        var chunkedResult: [(original: String, diffs: [WordDiff])] = []
        
        for sentence in sentences {
            let wordCount = analyzer.normalize(sentence).count
            var chunk: [WordDiff] = []
            var wordsTaken = 0
            
            while wordsTaken < wordCount && !tempDiffs.isEmpty {
                let diff = tempDiffs.removeFirst()
                chunk.append(diff)
                switch diff {
                case .matched, .missing, .replaced:
                    wordsTaken += 1
                case .extra:
                    break
                }
            }
            while let nextDiff = tempDiffs.first, case .extra = nextDiff {
                chunk.append(tempDiffs.removeFirst())
            }
            chunkedResult.append((original: sentence, diffs: chunk))
        }
        
        if !tempDiffs.isEmpty {
            if chunkedResult.isEmpty {
                chunkedResult.append((original: "", diffs: tempDiffs))
            } else {
                chunkedResult[chunkedResult.count - 1].diffs.append(contentsOf: tempDiffs)
            }
        }
        
        for (sIdx, sentenceData) in chunkedResult.enumerated() {
            var originalWordIndexInSentence = 0
            for diff in sentenceData.diffs {
                switch diff {
                case .matched:
                    originalWordIndexInSentence += 1
                    break
                case .missing(let expected):
                    detailsData.append((diff, expected, sIdx, originalWordIndexInSentence))
                    originalWordIndexInSentence += 1
                case .extra(let actual):
                    detailsData.append((diff, nil, sIdx, originalWordIndexInSentence))
                case .replaced(let expected, let actual):
                    detailsData.append((diff, expected, sIdx, originalWordIndexInSentence))
                    originalWordIndexInSentence += 1
                }
            }
        }
        
        let summary = try scriptManagementService.createFeedbackSummary(
            scriptId: script.id!,
            accuracy: accuracy, // Pass accuracy directly
            missingWordCount: missingCount,
            addedWordCount: extraCount,
            replacedWordCount: replacedCount,
            practiceDuration: practiceDuration, // Pass practiceDuration directly
            feedbackDetailsData: detailsData
        )
        
        let summaryIdBeforeViewModel = summary.id!
        
        // Load historical feedback
        let historicalViewModel = await MainActor.run {
            HistoricalFeedbackViewModel(
                summary: summary,
                scriptManagementService: scriptManagementService
            )
        }
        
        await historicalViewModel.loadFeedbackData() // Ensure this is awaited
        
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
        let script = try await createDummyScript(title: "Test Script", sentences: sentences)
        
        let diffs: [WordDiff] = [
            .matched(word: "hello"),
            .missing(expected: "world"),
            .matched(word: "everyone")
        ]
        let accuracy: Double = 2.0 / 3.0
        let practiceDuration: Double = 5.0
        
        // When: Create current feedback
        let currentViewModel = await MainActor.run {
            FeedbackViewModel(
                scriptId: script.id!,
                diffs: diffs,
                sentences: sentences,
                practiceDuration: practiceDuration,
                scriptManagementService: scriptManagementService
            )
        }
        
        let (missingCount, extraCount, replacedCount) = await MainActor.run {
            (currentViewModel.missingCount, currentViewModel.extraCount, currentViewModel.replacedCount)
        }
        
        // Construct detailsData directly
        var detailsData: [(wordDiff: WordDiff, originalText: String?, sentenceIndex: Int, wordIndex: Int)] = []
        let analyzer = SpeechAnalyzer()
        var tempDiffs = diffs
        var chunkedResult: [(original: String, diffs: [WordDiff])] = []
        
        for sentence in sentences {
            let wordCount = analyzer.normalize(sentence).count
            var chunk: [WordDiff] = []
            var wordsTaken = 0
            
            while wordsTaken < wordCount && !tempDiffs.isEmpty {
                let diff = tempDiffs.removeFirst()
                chunk.append(diff)
                switch diff {
                case .matched, .missing, .replaced:
                    wordsTaken += 1
                case .extra:
                    break
                }
            }
            while let nextDiff = tempDiffs.first, case .extra = nextDiff {
                chunk.append(tempDiffs.removeFirst())
            }
            chunkedResult.append((original: sentence, diffs: chunk))
        }
        
        if !tempDiffs.isEmpty {
            if chunkedResult.isEmpty {
                chunkedResult.append((original: "", diffs: tempDiffs))
            } else {
                chunkedResult[chunkedResult.count - 1].diffs.append(contentsOf: tempDiffs)
            }
        }
        
        for (sIdx, sentenceData) in chunkedResult.enumerated() {
            var originalWordIndexInSentence = 0
            for diff in sentenceData.diffs {
                switch diff {
                case .matched:
                    originalWordIndexInSentence += 1
                    break
                case .missing(let expected):
                    detailsData.append((diff, expected, sIdx, originalWordIndexInSentence))
                    originalWordIndexInSentence += 1
                case .extra(let actual):
                    detailsData.append((diff, nil, sIdx, originalWordIndexInSentence))
                case .replaced(let expected, let actual):
                    detailsData.append((diff, expected, sIdx, originalWordIndexInSentence))
                    originalWordIndexInSentence += 1
                }
            }
        }
        
        let summary = try scriptManagementService.createFeedbackSummary(
            scriptId: script.id!,
            accuracy: accuracy,
            missingWordCount: missingCount,
            addedWordCount: extraCount,
            replacedWordCount: replacedCount,
            practiceDuration: practiceDuration,
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
        let script = try await createDummyScript(title: "Test Script", sentences: sentences)
        
        let diffs: [WordDiff] = [
            .matched(word: "hello"),
            .replaced(expected: "world", actual: "earth")
        ]
        let accuracy: Double = 0.5
        let practiceDuration: Double = 5.0
        
        // When: Create current feedback
        let currentViewModel = await MainActor.run {
            FeedbackViewModel(
                scriptId: script.id!,
                diffs: diffs,
                sentences: sentences,
                practiceDuration: practiceDuration,
                scriptManagementService: scriptManagementService
            )
        }
        
        let (missingCount, extraCount, replacedCount) = await MainActor.run {
            (currentViewModel.missingCount, currentViewModel.extraCount, currentViewModel.replacedCount)
        }
        
        // Construct detailsData directly
        var detailsData: [(wordDiff: WordDiff, originalText: String?, sentenceIndex: Int, wordIndex: Int)] = []
        let analyzer = SpeechAnalyzer()
        var tempDiffs = diffs
        var chunkedResult: [(original: String, diffs: [WordDiff])] = []
        
        for sentence in sentences {
            let wordCount = analyzer.normalize(sentence).count
            var chunk: [WordDiff] = []
            var wordsTaken = 0
            
            while wordsTaken < wordCount && !tempDiffs.isEmpty {
                let diff = tempDiffs.removeFirst()
                chunk.append(diff)
                switch diff {
                case .matched, .missing, .replaced:
                    wordsTaken += 1
                case .extra:
                    break
                }
            }
            while let nextDiff = tempDiffs.first, case .extra = nextDiff {
                chunk.append(tempDiffs.removeFirst())
            }
            chunkedResult.append((original: sentence, diffs: chunk))
        }
        
        if !tempDiffs.isEmpty {
            if chunkedResult.isEmpty {
                chunkedResult.append((original: "", diffs: tempDiffs))
            } else {
                chunkedResult[chunkedResult.count - 1].diffs.append(contentsOf: tempDiffs)
            }
        }
        
        for (sIdx, sentenceData) in chunkedResult.enumerated() {
            var originalWordIndexInSentence = 0
            for diff in sentenceData.diffs {
                switch diff {
                case .matched:
                    originalWordIndexInSentence += 1
                    break
                case .missing(let expected):
                    detailsData.append((diff, expected, sIdx, originalWordIndexInSentence))
                    originalWordIndexInSentence += 1
                case .extra(let actual):
                    detailsData.append((diff, nil, sIdx, originalWordIndexInSentence))
                case .replaced(let expected, let actual):
                    detailsData.append((diff, expected, sIdx, originalWordIndexInSentence))
                    originalWordIndexInSentence += 1
                }
            }
        }
        
        let summary = try scriptManagementService.createFeedbackSummary(
            scriptId: script.id!,
            accuracy: accuracy,
            missingWordCount: missingCount,
            addedWordCount: extraCount,
            replacedWordCount: replacedCount,
            practiceDuration: practiceDuration,
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
        let script = try await createDummyScript(title: "Test Script", sentences: sentences)
        
        let diffs: [WordDiff] = [
            .matched(word: "hello"),
            .missing(expected: "beautiful"),
            .matched(word: "world"),
            .matched(word: "how"),
            .replaced(expected: "are", actual: "is"),
            .matched(word: "you"),
            .missing(expected: "doing")
        ]
        let accuracy: Double = 4.0 / 7.0
        let practiceDuration: Double = 12.0
        
        // When: Create current feedback
        let currentViewModel = await MainActor.run {
            FeedbackViewModel(
                scriptId: script.id!,
                diffs: diffs,
                sentences: sentences,
                practiceDuration: practiceDuration,
                scriptManagementService: scriptManagementService
            )
        }
        
        let (missingCount, extraCount, replacedCount) = await MainActor.run {
            (currentViewModel.missingCount, currentViewModel.extraCount, currentViewModel.replacedCount)
        }
        
        // Construct detailsData directly
        var detailsData: [(wordDiff: WordDiff, originalText: String?, sentenceIndex: Int, wordIndex: Int)] = []
        let analyzer = SpeechAnalyzer()
        var tempDiffs = diffs
        var chunkedResult: [(original: String, diffs: [WordDiff])] = []
        
        for sentence in sentences {
            let wordCount = analyzer.normalize(sentence).count
            var chunk: [WordDiff] = []
            var wordsTaken = 0
            
            while wordsTaken < wordCount && !tempDiffs.isEmpty {
                let diff = tempDiffs.removeFirst()
                chunk.append(diff)
                switch diff {
                case .matched, .missing, .replaced:
                    wordsTaken += 1
                case .extra:
                    break
                }
            }
            while let nextDiff = tempDiffs.first, case .extra = nextDiff {
                chunk.append(tempDiffs.removeFirst())
            }
            chunkedResult.append((original: sentence, diffs: chunk))
        }
        
        if !tempDiffs.isEmpty {
            if chunkedResult.isEmpty {
                chunkedResult.append((original: "", diffs: tempDiffs))
            } else {
                chunkedResult[chunkedResult.count - 1].diffs.append(contentsOf: tempDiffs)
            }
        }
        
        for (sIdx, sentenceData) in chunkedResult.enumerated() {
            var originalWordIndexInSentence = 0
            for diff in sentenceData.diffs {
                switch diff {
                case .matched:
                    originalWordIndexInSentence += 1
                    break
                case .missing(let expected):
                    detailsData.append((diff, expected, sIdx, originalWordIndexInSentence))
                    originalWordIndexInSentence += 1
                case .extra(let actual):
                    detailsData.append((diff, nil, sIdx, originalWordIndexInSentence))
                case .replaced(let expected, let actual):
                    detailsData.append((diff, expected, sIdx, originalWordIndexInSentence))
                    originalWordIndexInSentence += 1
                }
            }
        }
        
        let summary = try scriptManagementService.createFeedbackSummary(
            scriptId: script.id!,
            accuracy: accuracy,
            missingWordCount: missingCount,
            addedWordCount: extraCount,
            replacedWordCount: replacedCount,
            practiceDuration: practiceDuration,
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
}
