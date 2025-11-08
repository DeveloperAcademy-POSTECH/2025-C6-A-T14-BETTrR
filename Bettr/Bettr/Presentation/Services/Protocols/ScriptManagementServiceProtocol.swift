//
//  ScriptManagementServiceProtocol.swift
//  Bettr
//
//  Created by 길정수 on 11/3/25.
//

import Foundation
import GRDB

protocol ScriptManagementServiceProtocol {
    func fetchScriptWithSentencesAndChunks(id: Int64) throws -> (script: Script, sentences: [(sentence: Sentence, chunks: [Chunk])])?
    
    func fetchScriptWithSentences(id: Int64) throws -> (script: Script, sentences: [Sentence])?
    
    func createFeedbackSummary(
        scriptId: Int64,
        totalScore: Double,
        missingWordCount: Int,
        addedWordCount: Int,
        replacedWordCount: Int,
        practiceDuration: Double,
        feedbackDetailsData: [(
            errorType: FeedbackErrorType,
            originalText: String?,
            spokenText: String?,
            startTime: Double,
            endTime: Double
        )]
    ) throws -> FeedbackSummary
    
    func fetchFeedbackSummaries(forScriptId: Int64) throws -> [FeedbackSummary]
    
    func fetchFeedbackDetails(forFeedbackSummaryId feedbackSummaryId: Int64) throws -> [FeedbackDetail]
    
    func updateScriptTitle(scriptId: Int64, newTitle: String) throws
}

extension ScriptManagementService: ScriptManagementServiceProtocol { }
