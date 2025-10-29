
import Foundation
import GRDB

class ScriptRepository {
    private let dbQueue: DatabaseQueue
    init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
    }

    // MARK: - Script Create
    func createScript(scriptData: ScriptData) throws -> Script {
        try validateScriptData(scriptData)

        return try dbQueue.write { db in
            let script = try createAndSaveScript(scriptData, in: db)
            guard let scriptId = script.id else {
                throw ScriptRepositoryError.databaseError(message: "Failed to get ID for created Script")
            }

            for (sentenceOrderIndex, sentenceData) in scriptData.sentences.enumerated() {
                let sentence = try createAndSaveSentence(sentenceData, forScriptId: scriptId, orderIndex: sentenceOrderIndex, in: db)
                guard let sentenceId = sentence.id else {
                    throw ScriptRepositoryError.databaseError(message: "Failed to get ID for created Sentence")
                }

                for (chunkOrderIndex, chunkData) in sentenceData.chunks.enumerated() {
                    _ = try createAndSaveChunk(chunkData, forSentenceId: sentenceId, orderIndex: chunkOrderIndex, in: db)
                }
            }
            return script
        }
    }
    
    // MARK: - Script Read
    func fetchScript(id: Int64) throws -> Script? {
        return try dbQueue.read { db in
            try Script.fetchOne(db, key: id)
        }
    }

    func fetchAllScripts() throws -> [Script] {
        return try dbQueue.read { db in
            try Script.fetchAll(db)
        }
    }
    
    // MARK: - Script Update
    func updateLastViewedAt(forScriptId scriptId: Int64) throws {
        try dbQueue.write { db in
            guard var script = try Script.fetchOne(db, key: scriptId) else {
                throw ScriptRepositoryError.notFound(message: "Script with ID \(scriptId) not found.")
            }
            script.lastViewedAt = Date()
            do {
                try script.update(db)
            } catch {
                throw ScriptRepositoryError.databaseError(message: "Failed to update Script \(scriptId): \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - PracticeSession Create
    func createPracticeSession(scriptId: Int64, recordingPath: String, totalPresentationTime: Double) throws -> PracticeSession {
        return try dbQueue.write { db in
            
            guard let _ = try Script.fetchOne(db, key: scriptId) else {
                throw ScriptRepositoryError.notFound(message: "Script with ID \(scriptId) not found.")
            }

            var session = PracticeSession(
                scriptId: scriptId,
                recordingPath: recordingPath,
                totalPresentationTime: totalPresentationTime,
                createdAt: Date()
            )
            do {
                try session.save(db)
            } catch {
                throw ScriptRepositoryError.databaseError(message: "Failed to save PracticeSession: \(error.localizedDescription)")
            }
            return session
        }
    }

    // MARK: - FeedbackSummary Create
    func createFeedbackSummary(
        practiceSessionId: Int64,
        totalScore: Double,
        missingWordCount: Int,
        addedWordCount: Int,
        replacedWordCount: Int,
        feedbackDetailsData: [(errorType: FeedbackErrorType, originalText: String?, spokenText: String?, startTime: Double, endTime: Double)]
    ) throws -> FeedbackSummary {
        return try dbQueue.write { db in
            try validatePracticeSessionExists(db: db, practiceSessionId: practiceSessionId)
            try validateFeedbackSummaryUniqueness(db: db, practiceSessionId: practiceSessionId)
            try validateFeedbackDetailsData(feedbackDetailsData)

            let summary = try createAndSaveFeedbackSummary(
                db: db,
                practiceSessionId: practiceSessionId,
                totalScore: totalScore,
                missingWordCount: missingWordCount,
                addedWordCount: addedWordCount,
                replacedWordCount: replacedWordCount
            )
            guard let summaryId = summary.id else {
                throw ScriptRepositoryError.databaseError(message: "Failed to get ID for created FeedbackSummary")
            }

            for detailData in feedbackDetailsData {
                _ = try createAndSaveFeedbackDetail(db: db, feedbackSummaryId: summaryId, detailData: detailData)
            }
            return summary
        }
    }
    
    // MARK: - Private Methods
    private func validateScriptData(_ scriptData: ScriptData) throws {
        if scriptData.sentences.isEmpty {
            throw ScriptRepositoryError.validationError(message: "A Script must contain at least one sentence.")
        }

        for sentenceData in scriptData.sentences {
            if sentenceData.chunks.isEmpty {
                throw ScriptRepositoryError.validationError(message: "A Sentence must contain at least one chunk.")
            }
        }
    }

    private func createAndSaveScript(_ scriptData: ScriptData, in db: Database) throws -> Script {
        var script = Script(
            title: scriptData.title,
            createdAt: Date(),
            lastViewedAt: Date()
        )
        do {
            try script.save(db)
        } catch {
            throw ScriptRepositoryError.databaseError(message: "Failed to save Script: \(error.localizedDescription)")
        }
        return script
    }

    private func createAndSaveSentence(_ sentenceData: SentenceData, forScriptId scriptId: Int64, orderIndex: Int, in db: Database) throws -> Sentence {
        var sentence = Sentence(
            scriptId: scriptId,
            orderIndex: orderIndex,
            englishText: sentenceData.englishText,
            koreanText: sentenceData.koreanText
        )
        do {
            try sentence.save(db)
        } catch {
            throw ScriptRepositoryError.databaseError(message: "Failed to save Sentence: \(error.localizedDescription)")
        }
        return sentence
    }

    private func createAndSaveChunk(_ chunkData: ChunkData, forSentenceId sentenceId: Int64, orderIndex: Int, in db: Database) throws -> Chunk {
        var chunk = Chunk(
            sentenceId: sentenceId,
            orderIndex: orderIndex,
            englishText: chunkData.englishText,
            koreanText: chunkData.koreanText
        )
        do {
            try chunk.save(db)
        } catch {
            throw ScriptRepositoryError.databaseError(message: "Failed to save Chunk: \(error.localizedDescription)")
        }
        return chunk
    }

    private func validatePracticeSessionExists(db: Database, practiceSessionId: Int64) throws {
        guard let _ = try PracticeSession.fetchOne(db, key: practiceSessionId) else {
            throw ScriptRepositoryError.notFound(message: "PracticeSession with ID \(practiceSessionId) not found.")
        }
    }

    private func validateFeedbackSummaryUniqueness(db: Database, practiceSessionId: Int64) throws {
        if let _ = try FeedbackSummary.filter(Column("practiceSessionId") == practiceSessionId).fetchOne(db) {
            throw ScriptRepositoryError.validationError(message: "FeedbackSummary already exists for PracticeSession ID \(practiceSessionId).")
        }
    }

    private func validateFeedbackDetailsData(_ feedbackDetailsData: [(errorType: FeedbackErrorType, originalText: String?, spokenText: String?, startTime: Double, endTime: Double)]) throws {
        if feedbackDetailsData.isEmpty {
            throw ScriptRepositoryError.validationError(message: "FeedbackSummary must contain at least one FeedbackDetail.")
        }
    }

    private func createAndSaveFeedbackSummary(db: Database, practiceSessionId: Int64, totalScore: Double, missingWordCount: Int, addedWordCount: Int, replacedWordCount: Int) throws -> FeedbackSummary {
        var summary = FeedbackSummary(
            practiceSessionId: practiceSessionId,
            totalScore: totalScore,
            missingWordCount: missingWordCount,
            addedWordCount: addedWordCount,
            replacedWordCount: replacedWordCount,
            analyzedAt: Date()
        )
        do {
            try summary.save(db)
        } catch {
            throw ScriptRepositoryError.databaseError(message: "Failed to save FeedbackSummary: \(error.localizedDescription)")
        }
        return summary
    }

    private func createAndSaveFeedbackDetail(db: Database, feedbackSummaryId: Int64, detailData: (errorType: FeedbackErrorType, originalText: String?, spokenText: String?, startTime: Double, endTime: Double)) throws -> FeedbackDetail {
        var detail = FeedbackDetail(
            feedbackSummaryId: feedbackSummaryId,
            errorType: detailData.errorType,
            originalText: detailData.originalText,
            spokenText: detailData.spokenText,
            startTime: detailData.startTime,
            endTime: detailData.endTime
        )
        do {
            try detail.save(db)
        } catch {
            throw ScriptRepositoryError.databaseError(message: "Failed to save FeedbackDetail: \(error.localizedDescription)")
        }
        return detail
    }
}
