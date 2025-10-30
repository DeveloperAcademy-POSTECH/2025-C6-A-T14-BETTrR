import Foundation
import GRDB

class ScriptRepository {
    // MARK: - Script
    func save(script: inout Script, in db: Database) throws -> Script {
        try script.save(db)
        return script
    }
    
    func fetchScript(id: Int64, in db: Database) throws -> Script? {
        try Script.fetchOne(db, key: id)
    }

    func fetchAllScripts(in db: Database) throws -> [Script] {
        try Script.fetchAll(db)
    }

    func deleteScript(id: Int64, in db: Database) throws {
        let _ = try Script.deleteOne(db, key: id)
    }
    
    // MARK: - Sentence
    func save(sentence: inout Sentence, in db: Database) throws -> Sentence {
        try sentence.save(db)
        return sentence
    }
    
    func fetchSentences(forScriptId scriptId: Int64, in db: Database) throws -> [Sentence] {
        try Sentence
            .filter(Column("scriptId") == scriptId)
            .order(Column("orderIndex"))
            .fetchAll(db)
    }
    
    // MARK: - Chunk
    func save(chunk: inout Chunk, in db: Database) throws -> Chunk {
        try chunk.save(db)
        return chunk
    }
    
    func fetchChunks(forSentenceId sentenceId: Int64, in db: Database) throws -> [Chunk] {
        try Chunk
            .filter(Column("sentenceId") == sentenceId)
            .order(Column("orderIndex"))
            .fetchAll(db)
    }
    
    // MARK: - PracticeSession
    func save(practiceSession: inout PracticeSession, in db: Database) throws -> PracticeSession {
        try practiceSession.save(db)
        return practiceSession
    }
    
    func fetchPracticeSession(id: Int64, in db: Database) throws -> PracticeSession? {
        try PracticeSession.fetchOne(db, key: id)
    }

    func fetchPracticeSessions(forScriptId scriptId: Int64, in db: Database) throws -> [PracticeSession] {
        try PracticeSession.filter(Column("scriptId") == scriptId).fetchAll(db)
    }

    // MARK: - FeedbackSummary
    func save(feedbackSummary: inout FeedbackSummary, in db: Database) throws -> FeedbackSummary {
        try feedbackSummary.save(db)
        return feedbackSummary
    }
    
    func fetchFeedbackSummary(forPracticeSessionId practiceSessionId: Int64, in db: Database) throws -> FeedbackSummary? {
        try FeedbackSummary.filter(Column("practiceSessionId") == practiceSessionId).fetchOne(db)
    }

    // MARK: - FeedbackDetail
    func save(feedbackDetail: inout FeedbackDetail, in db: Database) throws -> FeedbackDetail {
        try feedbackDetail.save(db)
        return feedbackDetail
    }
    
    func fetchFeedbackDetails(forFeedbackSummaryId feedbackSummaryId: Int64, in db: Database) throws -> [FeedbackDetail] {
        try FeedbackDetail.filter(Column("feedbackSummaryId") == feedbackSummaryId).fetchAll(db)
    }
}
