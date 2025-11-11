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
    ) throws -> FeedbackSummary
    
    func fetchFeedbackSummaries(forScriptId: Int64) throws -> [FeedbackSummary]
    
    func fetchFeedbackDetails(forFeedbackSummaryId feedbackSummaryId: Int64) throws -> [FeedbackDetail]
    
    func updateScriptTitle(scriptId: Int64, newTitle: String) throws
}

extension ScriptManagementService: ScriptManagementServiceProtocol { }
