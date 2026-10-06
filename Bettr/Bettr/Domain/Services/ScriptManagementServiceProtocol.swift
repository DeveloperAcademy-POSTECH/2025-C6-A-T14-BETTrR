//
//  ScriptManagementServiceProtocol.swift
//  Bettr
//
//  Created by 길정수 on 11/3/25.
//

import Foundation

/// 홈 목록은 조회와 삭제 계약만 사용합니다.
@MainActor
protocol HomeScriptServicing {
    func fetchAllScripts() async throws -> [Script]
    func deleteScript(id: Int64) async throws
}

/// UI 호출은 MainActor에서 시작하며, DB 작업은 GRDB queue에 위임합니다.
@MainActor
protocol ScriptManagementServiceProtocol: HomeScriptServicing {
    // MARK: - Script Create
    func createScript(scriptData: ScriptData) async throws -> Script

    // MARK: - Script Read
    func fetchScript(id: Int64) async throws -> Script?
    // MARK: - Script Read with Relations
    func fetchScriptWithSentences(id: Int64) async throws -> (script: Script, sentences: [Sentence])
    func fetchScriptWithSentencesAndChunks(id: Int64) async throws -> (script: Script, sentences: [(sentence: Sentence, chunks: [Chunk])])

    // MARK: - Script Update
    func updateLastViewedAt(forScriptId scriptId: Int64) async throws
    func updateScriptTitle(scriptId: Int64, newTitle: String) async throws

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
