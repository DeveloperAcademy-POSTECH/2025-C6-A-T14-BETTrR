
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
            // 1. scriptId 존재 여부 유효성 검사
            guard let _ = try Script.fetchOne(db, key: scriptId) else {
                throw ScriptRepositoryError.notFound(message: "Script with ID \(scriptId) not found.")
            }

            // 2. 연습 세션 생성 및 저장
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
        feedbackDetailsData: [(errorType: String, originalText: String?, spokenText: String?, startTime: Double, endTime: Double)]
    ) throws -> FeedbackSummary {
        return try dbQueue.write { db in
            // 1. practiceSessionId 존재 여부 유효성 검사
            guard let _ = try PracticeSession.fetchOne(db, key: practiceSessionId) else {
                throw ScriptRepositoryError.notFound(message: "PracticeSession with ID \(practiceSessionId) not found.")
            }

            // 2. FeedbackSummary 고유성 검사 (1:1 관계)
            if let _ = try FeedbackSummary.filter(Column("practiceSessionId") == practiceSessionId).fetchOne(db) {
                throw ScriptRepositoryError.validationError(message: "FeedbackSummary already exists for PracticeSession ID \(practiceSessionId).")
            }

            // 3. feedbackDetailsData 비어 있지 않음 유효성 검사
            if feedbackDetailsData.isEmpty {
                throw ScriptRepositoryError.validationError(message: "FeedbackSummary must contain at least one FeedbackDetail.")
            }

            // 4. errorType 유효성 검사
            let allowedErrorTypes: Set<String> = ["누락된 단어", "추가된 단어", "대체된 단어"]
            for detailData in feedbackDetailsData {
                if !allowedErrorTypes.contains(detailData.errorType) {
                    throw ScriptRepositoryError.validationError(message: "Invalid errorType: \(detailData.errorType). Allowed types are: \(allowedErrorTypes.joined(separator: ", ")).")
                }
            }

            // 5. FeedbackSummary 생성 및 저장
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
            guard let summaryId = summary.id else {
                throw ScriptRepositoryError.databaseError(message: "Failed to get ID for created FeedbackSummary")
            }

            // 6. FeedbackDetail 생성 및 저장
            for detailData in feedbackDetailsData {
                var detail = FeedbackDetail(
                    feedbackSummaryId: summaryId,
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
}
