//
//  ScriptManagementServiceProtocol.swift
//  Bettr
//
//  Created by 길정수 on 11/3/25.
//

import Foundation
import GRDB

protocol ScriptManagementServiceProtocol {
    // MARK: - Script Create
    func createScript(scriptData: ScriptData) async throws -> Script

    // MARK: - Script Read
    func fetchScript(id: Int64) async throws -> Script?
    func fetchAllScripts() async throws -> [Script]
    
    // MARK: - Script Read with Relations
    func fetchScriptWithSentences(id: Int64) async throws -> (script: Script, sentences: [Sentence])?
    func fetchScriptWithSentencesAndChunks(id: Int64) async throws -> (script: Script, sentences: [(sentence: Sentence, chunks: [Chunk])])?

    // MARK: - Script Update
    func updateLastViewedAt(forScriptId scriptId: Int64) async throws
    func updateScriptTitle(scriptId: Int64, newTitle: String) async throws

    // MARK: - Script Delete
    func deleteScript(id: Int64) async throws

    // MARK: - Feedback Read
    func fetchAllFeedbackSummaries() async throws -> [FeedbackSummary]
    func fetchFeedbackSummaries(forScriptId scriptId: Int64) async throws -> [FeedbackSummary]
    func fetchFeedbackDetails(forFeedbackSummaryId feedbackSummaryId: Int64) async throws -> [FeedbackDetail]

    // MARK: - Feedback Create
    func createFeedbackSummary(
        scriptId: Int64,
        accuracy: Double,
        missingWordCount: Int,
        addedWordCount: Int,
        replacedWordCount: Int,
        practiceDuration: Double,
        feedbackDetailsData: [(
            wordDiff: WordDiff,
            originalText: String?,
            sentenceIndex: Int,
            wordIndex: Int
        )]
    ) async throws -> FeedbackSummary
}

extension ScriptManagementService: ScriptManagementServiceProtocol { }
