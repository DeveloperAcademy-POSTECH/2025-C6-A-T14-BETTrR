import Foundation
import GRDB

class ScriptManagementService {
    private let scriptRepository: ScriptRepository

    init(scriptRepository: ScriptRepository) {
        self.scriptRepository = scriptRepository
    }

    // MARK: - Script Create
    func createScript(scriptData: ScriptData) async throws -> Script {
        try validateScriptData(scriptData)

        var script = Script(
            title: scriptData.title,
            createdAt: Date(),
            lastViewedAt: Date()
        )
        script = try await scriptRepository.save(script: script)
        
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
            sentence = try await scriptRepository.save(sentence: sentence)
            
            guard let sentenceId = sentence.id else {
                throw ScriptRepositoryError.databaseError(message: "Failed to get ID for created Sentence")
            }

            for (chunkOrderIndex, chunkData) in sentenceData.chunks.enumerated() {
                let chunk = Chunk(
                    sentenceId: sentenceId,
                    orderIndex: chunkOrderIndex,
                    englishText: chunkData.englishText,
                    koreanText: chunkData.koreanText
                )
                _ = try await scriptRepository.save(chunk: chunk)
            }
        }
        return script
    }
    
    // MARK: - Script Read
    func fetchScript(id: Int64) async throws -> Script? {
        return try await scriptRepository.fetchScript(id: id)
    }

    func fetchAllScripts() async throws -> [Script] {
        return try await scriptRepository.fetchAllScripts()
    }
    
    // MARK: - Script Read with Relations
    func fetchScriptWithSentences(id: Int64) async throws -> (script: Script, sentences: [Sentence]) {
        guard let script = try await scriptRepository.fetchScript(id: id) else {
            throw ScriptRepositoryError.notFound(message: "Script with ID \(id) not found.")
        }
        let sentences = try await scriptRepository.fetchSentences(forScriptId: script.id!)
        return (script, sentences)
    }

    func fetchScriptWithSentencesAndChunks(id: Int64) async throws -> (script: Script, sentences: [(sentence: Sentence, chunks: [Chunk])]) {
        guard let script = try await scriptRepository.fetchScript(id: id) else {
            throw ScriptRepositoryError.notFound(message: "Script with ID \(id) not found.")
        }
        
        let sentences = try await scriptRepository.fetchSentences(forScriptId: script.id!)
        var sentencesWithChunks: [(sentence: Sentence, chunks: [Chunk])] = []
        
        for sentence in sentences {
            let chunks = try await scriptRepository.fetchChunks(forSentenceId: sentence.id!)
            sentencesWithChunks.append((sentence: sentence, chunks: chunks))
        }
        
        return (script, sentencesWithChunks)
    }

    // MARK: - Script Update
    func updateLastViewedAt(forScriptId scriptId: Int64) async throws {
        guard var script = try await scriptRepository.fetchScript(id: scriptId) else {
            throw ScriptRepositoryError.notFound(message: "Script with ID \(scriptId) not found.")
        }
        script.lastViewedAt = Date()
        _ = try await scriptRepository.save(script: script)
    }
    
    func updateScriptTitle(scriptId: Int64, newTitle: String) async throws {
        try await scriptRepository.updateScriptTitle(id: scriptId, newTitle: newTitle)
    }

    // MARK: - Script Delete
    func deleteScript(id: Int64) async throws {
        try await scriptRepository.deleteScript(id: id)
    }

    // MARK: - Feedback Read
    func fetchAllFeedbackSummaries() async throws -> [FeedbackSummary] {
        try await scriptRepository.fetchAllFeedbackSummaries()
    }
    
    func fetchFeedbackSummaries(forScriptId scriptId: Int64) async throws -> [FeedbackSummary] {
        try await scriptRepository.fetchFeedbackSummaries(forScriptId: scriptId)
    }
    
    func fetchFeedbackDetails(forFeedbackSummaryId feedbackSummaryId: Int64) async throws -> [FeedbackDetail] {
        try await scriptRepository.fetchFeedbackDetails(forFeedbackSummaryId: feedbackSummaryId)
    }

    // MARK: - Feedback Create
    func createFeedbackSummary(
        scriptId: Int64,
        accuracy: Double,
        missingWordCount: Int,
        addedWordCount: Int,
        replacedWordCount: Int,
        practiceDuration: Double,
        feedbackDetailsData: [(wordDiff: WordDiff, originalText: String?, sentenceIndex: Int, wordIndex: Int)]
    ) async throws -> FeedbackSummary {
        try await scriptRepository.createFeedbackSummaryWithDetails(
            scriptId: scriptId,
            accuracy: accuracy,
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
