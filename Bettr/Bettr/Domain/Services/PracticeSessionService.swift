
import Foundation
import GRDB

class PracticeSessionService {
    private let dbQueue: DatabaseQueue
    private let scriptRepository: ScriptRepository

    init(dbQueue: DatabaseQueue, scriptRepository: ScriptRepository) {
        self.dbQueue = dbQueue
        self.scriptRepository = scriptRepository
    }

    // MARK: - PracticeSession Create
    func createPracticeSession(scriptId: Int64, recordingPath: String, totalPresentationTime: Double) throws -> PracticeSession {
        return try dbQueue.write { db in
            try validateScriptExists(db: db, scriptId: scriptId)

            var session = PracticeSession(
                scriptId: scriptId,
                recordingPath: recordingPath,
                totalPresentationTime: totalPresentationTime,
                createdAt: Date()
            )
            _ = try scriptRepository.save(practiceSession: &session, in: db)
            return session
        }
    }

    // MARK: - PracticeSession Read
    func fetchPracticeSession(id: Int64) throws -> PracticeSession? {
        return try dbQueue.read { db in
            try scriptRepository.fetchPracticeSession(id: id, in: db)
        }
    }

    func fetchPracticeSessions(forScriptId scriptId: Int64) throws -> [PracticeSession] {
        return try dbQueue.read { db in
            try scriptRepository.fetchPracticeSessions(forScriptId: scriptId, in: db)
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

            var summary = FeedbackSummary(
                practiceSessionId: practiceSessionId,
                totalScore: totalScore,
                missingWordCount: missingWordCount,
                addedWordCount: addedWordCount,
                replacedWordCount: replacedWordCount,
                analyzedAt: Date()
            )
            _ = try scriptRepository.save(feedbackSummary: &summary, in: db)
            
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
                _ = try scriptRepository.save(feedbackDetail: &detail, in: db)
            }
            return summary
        }
    }

    // MARK: - Feedback Read
    func fetchFeedbackSummary(forPracticeSessionId practiceSessionId: Int64) throws -> FeedbackSummary? {
        return try dbQueue.read { db in
            try scriptRepository.fetchFeedbackSummary(forPracticeSessionId: practiceSessionId, in: db)
        }
    }

    func fetchFeedbackDetails(forFeedbackSummaryId feedbackSummaryId: Int64) throws -> [FeedbackDetail] {
        return try dbQueue.read { db in
            try scriptRepository.fetchFeedbackDetails(forFeedbackSummaryId: feedbackSummaryId, in: db)
        }
    }

    // MARK: - Private Methods (Validation)
    private func validateScriptExists(db: Database, scriptId: Int64) throws {
        guard let _ = try scriptRepository.fetchScript(id: scriptId, in: db) else {
            throw ScriptRepositoryError.notFound(message: "Script with ID \(scriptId) not found.")
        }
    }

    private func validatePracticeSessionExists(db: Database, practiceSessionId: Int64) throws {
        guard let _ = try scriptRepository.fetchPracticeSession(id: practiceSessionId, in: db) else {
            throw ScriptRepositoryError.notFound(message: "PracticeSession with ID \(practiceSessionId) not found.")
        }
    }

    private func validateFeedbackSummaryUniqueness(db: Database, practiceSessionId: Int64) throws {
        if let _ = try scriptRepository.fetchFeedbackSummary(forPracticeSessionId: practiceSessionId, in: db) {
            throw ScriptRepositoryError.validationError(message: "FeedbackSummary already exists for PracticeSession ID \(practiceSessionId).")
        }
    }

    private func validateFeedbackDetailsData(_ feedbackDetailsData: [(errorType: FeedbackErrorType, originalText: String?, spokenText: String?, startTime: Double, endTime: Double)]) throws {
        if feedbackDetailsData.isEmpty {
            throw ScriptRepositoryError.validationError(message: "FeedbackSummary must contain at least one FeedbackDetail.")
        }
    }
}
