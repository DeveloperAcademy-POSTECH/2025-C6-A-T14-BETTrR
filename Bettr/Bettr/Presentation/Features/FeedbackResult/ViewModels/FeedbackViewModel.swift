//
//  FeedbackViewModel.swift
//  Bettr
//
//  Created by 길정수 on 11/4/25.
//

import Foundation
import SwiftUI

@Observable
class FeedbackViewModel {
    
    // MARK: - 1. UI State Properties
    var isSaving = false
    var saveError: AppError? = nil
    
    // MARK: - 2. View-Specific Logic Properties
    let resultModel: FeedbackResultModel
    
    // MARK: - 4. Private Properties & Dependencies
    
    private let scriptId: Int64
    private let practiceDuration: Double
    
    private let detailParamsToSave: [FeedbackDetailParams]
    
    private let scriptManagementService: ScriptManagementServiceProtocol
    
    // MARK: - 5. Initializer
    
    init(
        scriptId: Int64,
        scriptTitle: String,
        currentFeedbackCount: Int,
        diffs: [WordDiff],
        sentences: [String],
        practiceDuration: Double,
        scriptManagementService: ScriptManagementServiceProtocol,
        processor: FeedbackResultProcessor = FeedbackResultProcessor()
    ) {
        self.scriptId = scriptId
        self.practiceDuration = practiceDuration
        self.scriptManagementService = scriptManagementService
        
        let (model, params) = processor.generateResult(
            fromLiveAnalysis: scriptTitle,
            currentFeedbackCount: currentFeedbackCount,
            diffs: diffs,
            sentences: sentences,
            practiceDuration: practiceDuration
        )
        
        self.resultModel = model
        self.detailParamsToSave = params
    }
    
    // MARK: - 6. Core Logic (DB Save)
    
    func saveFeedbackResult() async {
        isSaving = true
        saveError = nil
        
        let detailsAsTuples = self.detailParamsToSave.map { param in
            return (
                wordDiff: param.wordDiff,
                originalText: param.originalText,
                sentenceIndex: param.sentenceIndex,
                wordIndex: param.wordIndex
            )
        }
        
        do {
            let summary = try await self.scriptManagementService.createFeedbackSummary(
                scriptId: self.scriptId,
                accuracy: self.resultModel.accuracy,
                missingWordCount: self.resultModel.missingCount,
                addedWordCount: self.resultModel.extraCount,
                replacedWordCount: self.resultModel.replacedCount,
                practiceDuration: self.practiceDuration,
                feedbackDetailsData: detailsAsTuples
            )
            print("피드백 저장 성공. Summary ID: \(summary.id ?? -1)")
            isSaving = false
            
        }catch {
            print("피드백 저장 실패: \(error)")
            self.saveError = .apiError("피드백 저장에 실패했습니다. \(error.localizedDescription)")
            isSaving = false
        }
    }
}
