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
    /// 단일 transaction의 commit 결과를 반환합니다. 일반 저장 오류는 rollback을 뜻합니다.
    /// 호출 Task의 취소는 rollback의 증거가 아니므로, 결과를 조정해야 하는 호출부는
    /// 저장 Task를 취소하지 않고 실제 반환/오류를 관찰해야 합니다.
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
