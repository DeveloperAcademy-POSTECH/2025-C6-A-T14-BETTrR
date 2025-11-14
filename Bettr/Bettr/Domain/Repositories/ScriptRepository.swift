
import Foundation
import GRDB

class ScriptRepository {
    private let dbQueue: DatabaseQueue

    init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
    }

    // MARK: - Public Methods

    // MARK: Script
    func save(script: Script) async throws -> Script {
        return try await dbQueue.write { db in
            var script = script
            try script.save(db)
            return script
        }
    }

    func fetchScript(id: Int64) async throws -> Script? {
        try await dbQueue.read { db in
            try Script.fetchOne(db, key: id)
        }
    }

    func fetchAllScripts() async throws -> [Script] {
        try await dbQueue.read { db in
            try Script.fetchAll(db)
        }
    }

    func deleteScript(id: Int64) async throws {
        try await dbQueue.write { db in
            if try Script.deleteOne(db, key: id) == false {
                throw ScriptRepositoryError.notFound(message: "Script with ID \(id) not found.")
            }
        }
    }
    
    func updateScriptTitle(id: Int64, newTitle: String) async throws {
        try await dbQueue.write { db in
            guard var script = try Script.fetchOne(db, key: id) else {
                throw ScriptRepositoryError.notFound(message: "Script with ID \(id) not found.")
            }
            script.title = newTitle
            try script.save(db)
        }
    }

    // MARK: Sentence
    func save(sentence: Sentence) async throws -> Sentence {
        return try await dbQueue.write { db in
            var sentence = sentence
            try sentence.save(db)
            return sentence
        }
    }

    func fetchSentences(forScriptId scriptId: Int64) async throws -> [Sentence] {
        try await dbQueue.read { db in
            try Sentence
                .filter(Column("scriptId") == scriptId)
                .order(Column("orderIndex"))
                .fetchAll(db)
        }
    }

    // MARK: Chunk
    func save(chunk: Chunk) async throws -> Chunk {
        return try await dbQueue.write { db in
            var chunk = chunk
            try chunk.save(db)
            return chunk
        }
    }

    func fetchChunks(forSentenceId sentenceId: Int64) async throws -> [Chunk] {
        try await dbQueue.read { db in
            try Chunk
                .filter(Column("sentenceId") == sentenceId)
                .order(Column("orderIndex"))
                .fetchAll(db)
        }
    }

    // MARK: FeedbackSummary
    func fetchAllFeedbackSummaries() async throws -> [FeedbackSummary] {
        try await dbQueue.read { db in
            try FeedbackSummary.fetchAll(db)
        }
    }

    func fetchFeedbackSummaries(forScriptId scriptId: Int64) async throws -> [FeedbackSummary] {
        try await dbQueue.read { db in
            try FeedbackSummary.filter(Column("scriptId") == scriptId).fetchAll(db)
        }
    }
    
    func createFeedbackSummaryWithDetails(
        scriptId: Int64,
        accuracy: Double,
        missingWordCount: Int,
        addedWordCount: Int,
        replacedWordCount: Int,
        practiceDuration: Double,
        feedbackDetailsData: [(wordDiff: WordDiff, originalText: String?, sentenceIndex: Int, wordIndex: Int)]
    ) async throws -> FeedbackSummary {
        // Define a temporary struct to hold pre-calculated values.
        // This struct is Sendable because all its properties are Sendable.
        struct DetailInfo: Sendable {
            let wordDiffType: String
            let wordDiffExpected: String?
            let wordDiffActual: String?
            let originalText: String?
            let sentenceIndex: Int
            let wordIndex: Int
        }

        // Map the input data to the Sendable struct *before* the closure.
        // The access to `dbTypeValue` and other properties happens here, on the original actor.
        let detailInfos = feedbackDetailsData.map { detailData -> DetailInfo in
            let wordDiff = detailData.wordDiff
            return DetailInfo(
                wordDiffType: wordDiff.dbTypeValue,
                wordDiffExpected: {
                    switch wordDiff {
                    case .missing(let expected), .replaced(let expected, _): return expected
                    default: return nil
                    }
                }(),
                wordDiffActual: {
                    switch wordDiff {
                    case .extra(let actual), .replaced(_, let actual): return actual
                    default: return nil
                    }
                }(),
                originalText: detailData.originalText,
                sentenceIndex: detailData.sentenceIndex,
                wordIndex: detailData.wordIndex
            )
        }

        return try await dbQueue.write { db in
            var summary = FeedbackSummary(
                scriptId: scriptId,
                accuracy: accuracy,
                missingWordCount: missingWordCount,
                addedWordCount: addedWordCount,
                replacedWordCount: replacedWordCount,
                practiceDuration: practiceDuration,
                createdAt: Date()
            )
            try summary.save(db)
            
            guard let summaryId = summary.id else {
                throw ScriptRepositoryError.databaseError(message: "Failed to get ID for created FeedbackSummary")
            }
            
            // Inside the @Sendable closure, only use the pre-calculated, Sendable data.
            for info in detailInfos {
                var detail = FeedbackDetail(
                    feedbackSummaryId: summaryId,
                    wordDiffType: info.wordDiffType,
                    wordDiffExpected: info.wordDiffExpected,
                    wordDiffActual: info.wordDiffActual,
                    originalText: info.originalText,
                    sentenceIndex: info.sentenceIndex,
                    wordIndex: info.wordIndex
                )
                try detail.save(db)
            }
            
            return summary
        }
    }

    // MARK: - FeedbackDetail
    func fetchFeedbackDetails(forFeedbackSummaryId feedbackSummaryId: Int64) async throws -> [FeedbackDetail] {
        try await dbQueue.read { db in
            try FeedbackDetail.filter(Column("feedbackSummaryId") == feedbackSummaryId).fetchAll(db)
        }
    }
    
    // MARK: - Word
    nonisolated func save(word: inout Word, in db: Database) throws -> Word {
        try word.save(db)
        return word
    }

    nonisolated func fetchWords(forScriptId scriptId: Int64, in db: Database) throws -> [Word] {
        try Word
            .filter(Column("scriptId") == scriptId)
            .order(Column("orderIndex"))
            .fetchAll(db)
    }

    nonisolated func deleteWords(forScriptId scriptId: Int64, in db: Database) throws {
        try Word.filter(Column("scriptId") == scriptId).deleteAll(db)
    }
}
