
import Foundation
import GRDB

class ScriptRepository {
    private let dbQueue: DatabaseQueue

    init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
    }

    // MARK: - Public Methods

    // MARK: Script
    func save(script: inout Script) throws -> Script {
        try dbQueue.write { db in
            try script.save(db)
            return script
        }
    }

    func fetchScript(id: Int64) throws -> Script? {
        try dbQueue.read { db in
            try Script.fetchOne(db, key: id)
        }
    }

    func fetchAllScripts() throws -> [Script] {
        try dbQueue.read { db in
            try Script.fetchAll(db)
        }
    }

    func deleteScript(id: Int64) throws {
        try dbQueue.write { db in
            if try Script.deleteOne(db, key: id) == false {
                throw ScriptRepositoryError.notFound(message: "Script with ID \(id) not found.")
            }
        }
    }
    
    func updateScriptTitle(id: Int64, newTitle: String) throws {
        try dbQueue.write { db in
            guard var script = try Script.fetchOne(db, key: id) else {
                throw ScriptRepositoryError.notFound(message: "Script with ID \(id) not found.")
            }
            script.title = newTitle
            try script.save(db)
        }
    }

    // MARK: Sentence
    func save(sentence: inout Sentence) throws -> Sentence {
        try dbQueue.write { db in
            try sentence.save(db)
            return sentence
        }
    }

    func fetchSentences(forScriptId scriptId: Int64) throws -> [Sentence] {
        try dbQueue.read { db in
            try Sentence
                .filter(Column("scriptId") == scriptId)
                .order(Column("orderIndex"))
                .fetchAll(db)
        }
    }

    // MARK: Chunk
    func save(chunk: inout Chunk) throws -> Chunk {
        try dbQueue.write { db in
            try chunk.save(db)
            return chunk
        }
    }

    func fetchChunks(forSentenceId sentenceId: Int64) throws -> [Chunk] {
        try dbQueue.read { db in
            try Chunk
                .filter(Column("sentenceId") == sentenceId)
                .order(Column("orderIndex"))
                .fetchAll(db)
        }
    }

    // MARK: FeedbackSummary
    func fetchAllFeedbackSummaries() throws -> [FeedbackSummary] {
        try dbQueue.read { db in
            try FeedbackSummary.fetchAll(db)
        }
    }

    func fetchFeedbackSummaries(forScriptId scriptId: Int64) throws -> [FeedbackSummary] {
        try dbQueue.read { db in
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
    ) throws -> FeedbackSummary {
        try dbQueue.write { db in
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
            
            for detailData in feedbackDetailsData {
                var detail = FeedbackDetail(
                    feedbackSummaryId: summaryId,
                    wordDiffType: detailData.wordDiff.dbTypeValue,
                    wordDiffExpected: {
                        switch detailData.wordDiff {
                        case .missing(let expected), .replaced(let expected, _): return expected
                        default: return nil
                        }
                    }(),
                    wordDiffActual: {
                        switch detailData.wordDiff {
                        case .extra(let actual), .replaced(_, let actual): return actual
                        default: return nil
                        }
                    }(),
                    originalText: detailData.originalText, // Keep originalText
                    sentenceIndex: detailData.sentenceIndex,
                    wordIndex: detailData.wordIndex
                )
                try detail.save(db)
            }
            
            return summary
        }
    }

    // MARK: - FeedbackDetail
    func fetchFeedbackDetails(forFeedbackSummaryId feedbackSummaryId: Int64) throws -> [FeedbackDetail] {
        try dbQueue.read { db in
            try FeedbackDetail.filter(Column("feedbackSummaryId") == feedbackSummaryId).fetchAll(db)
        }
    }
    
    // MARK: - Word
    func save(word: inout Word, in db: Database) throws -> Word {
        try word.save(db)
        return word
    }

    func fetchWords(forScriptId scriptId: Int64, in db: Database) throws -> [Word] {
        try Word
            .filter(Column("scriptId") == scriptId)
            .order(Column("orderIndex"))
            .fetchAll(db)
    }

    func deleteWords(forScriptId scriptId: Int64, in db: Database) throws {
        try Word.filter(Column("scriptId") == scriptId).deleteAll(db)
    }
}
