import Foundation
import GRDB

class ScriptManagementService {
    private let scriptRepository: ScriptRepository

    init(scriptRepository: ScriptRepository) {
        self.scriptRepository = scriptRepository
    }

    // MARK: - Script Create
    func createScript(scriptData: ScriptData) throws -> Script {
        try validateScriptData(scriptData)

        var script = Script(
            title: scriptData.title,
            createdAt: Date(),
            lastViewedAt: Date()
        )
        script = try scriptRepository.save(script: &script)
        
        guard let scriptId = script.id else {
            throw ScriptRepositoryError.databaseError(message: "Failed to get ID for created Script")
        }

        for (sentenceOrderIndex, sentenceData) in scriptData.sentences.enumerated() {
            var sentence = Sentence(
                scriptId: scriptId,
                orderIndex: sentenceOrderIndex,
                englishText: sentenceData.englishText,
                koreanText: sentenceData.koreanText
            )
            sentence = try scriptRepository.save(sentence: &sentence)
            
            guard let sentenceId = sentence.id else {
                throw ScriptRepositoryError.databaseError(message: "Failed to get ID for created Sentence")
            }

            for (chunkOrderIndex, chunkData) in sentenceData.chunks.enumerated() {
                var chunk = Chunk(
                    sentenceId: sentenceId,
                    orderIndex: chunkOrderIndex,
                    englishText: chunkData.englishText,
                    koreanText: chunkData.koreanText
                )
                _ = try scriptRepository.save(chunk: &chunk)
            }
        }
        return script
    }
    
    // MARK: - Script Read
    func fetchScript(id: Int64) throws -> Script? {
        return try scriptRepository.fetchScript(id: id)
    }

    func fetchAllScripts() throws -> [Script] {
        return try scriptRepository.fetchAllScripts()
    }
    
    // MARK: - Script Read with Relations
    func fetchScriptWithSentences(id: Int64) throws -> (script: Script, sentences: [Sentence])? {
        guard let script = try scriptRepository.fetchScript(id: id) else {
            return nil
        }
        let sentences = try scriptRepository.fetchSentences(forScriptId: script.id!)
        return (script, sentences)
    }

    func fetchScriptWithSentencesAndChunks(id: Int64) throws -> (script: Script, sentences: [(sentence: Sentence, chunks: [Chunk])])? {
        guard let script = try scriptRepository.fetchScript(id: id) else {
            return nil
        }
        
        let sentences = try scriptRepository.fetchSentences(forScriptId: script.id!)
        var sentencesWithChunks: [(sentence: Sentence, chunks: [Chunk])] = []
        
        for sentence in sentences {
            let chunks = try scriptRepository.fetchChunks(forSentenceId: sentence.id!)
            sentencesWithChunks.append((sentence: sentence, chunks: chunks))
        }
        
        return (script, sentencesWithChunks)
    }

    // MARK: - Script Update
    func updateLastViewedAt(forScriptId scriptId: Int64) throws {
        guard var script = try scriptRepository.fetchScript(id: scriptId) else {
            throw ScriptRepositoryError.notFound(message: "Script with ID \(scriptId) not found.")
        }
        script.lastViewedAt = Date()
        _ = try scriptRepository.save(script: &script)
    }

    // MARK: - Script Delete
    func deleteScript(id: Int64) throws {
        try scriptRepository.deleteScript(id: id)
    }

    // MARK: - Feedback Read
    func fetchAllFeedbackSummaries() throws -> [FeedbackSummary] {
        try scriptRepository.fetchAllFeedbackSummaries()
    }
    
    func fetchFeedbackSummaries(forScriptId scriptId: Int64) throws -> [FeedbackSummary] {
        try scriptRepository.fetchFeedbackSummaries(forScriptId: scriptId)
    }
    
    func fetchFeedbackDetails(forFeedbackSummaryId feedbackSummaryId: Int64) throws -> [FeedbackDetail] {
        try scriptRepository.fetchFeedbackDetails(forFeedbackSummaryId: feedbackSummaryId)
    }

    // MARK: - Feedback Create
    func createFeedbackSummary(
        scriptId: Int64,
        totalScore: Double,
        missingWordCount: Int,
        addedWordCount: Int,
        replacedWordCount: Int,
        practiceDuration: Double,
        feedbackDetailsData: [(errorType: FeedbackErrorType, originalText: String?, spokenText: String?, startTime: Double, endTime: Double)]
    ) throws -> FeedbackSummary {
        try scriptRepository.createFeedbackSummaryWithDetails(
            scriptId: scriptId,
            totalScore: totalScore,
            missingWordCount: missingWordCount,
            addedWordCount: addedWordCount,
            replacedWordCount: replacedWordCount,
            practiceDuration: practiceDuration,
            feedbackDetailsData: feedbackDetailsData
        )
    }

    // MARK: - Private Methods (Validation)
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
}
