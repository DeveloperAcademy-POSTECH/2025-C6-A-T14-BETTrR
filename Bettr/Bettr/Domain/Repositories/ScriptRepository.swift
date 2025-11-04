
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
        totalScore: Double,
        missingWordCount: Int,
        addedWordCount: Int,
        replacedWordCount: Int,
        practiceDuration: Double,
        feedbackDetailsData: [(errorType: FeedbackErrorType, originalText: String?, spokenText: String?, startTime: Double, endTime: Double)]
    ) throws -> FeedbackSummary {
        try dbQueue.write { db in
            var summary = FeedbackSummary(
                scriptId: scriptId,
                totalScore: totalScore,
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
                    errorType: detailData.errorType,
                    originalText: detailData.originalText,
                    spokenText: detailData.spokenText,
                    startTime: detailData.startTime,
                    endTime: detailData.endTime
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
}
