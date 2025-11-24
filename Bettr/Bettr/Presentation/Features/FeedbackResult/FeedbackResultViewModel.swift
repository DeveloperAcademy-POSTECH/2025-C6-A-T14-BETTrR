//
//  FeedbackResultViewModel.swift
//  Bettr
//
//  Created by 길정수 on 11/4/25.
//

import Foundation
import SwiftUI

@Observable
class FeedbackResultViewModel {
    
    // MARK: - UI State Properties
    var isLoading = true
    var currentError: AppError? = nil
    
    // MARK: - View-Specific Logic Properties
    var resultModel: FeedbackResultModel?
    
    // MARK: - Private Properties & Dependencies
    
    private let scriptId: Int64
    private let targetSummaryId: Int64
    private let scriptManagementService: ScriptManagementServiceProtocol
    private let processor: FeedbackResultProcessor
    
    // MARK: - Initializer
    
    init(
        scriptId: Int64,
        summaryId: Int64,
        scriptManagementService: ScriptManagementServiceProtocol,
        processor: FeedbackResultProcessor = FeedbackResultProcessor()
    ) {
        self.scriptId = scriptId
        self.targetSummaryId = summaryId
        self.scriptManagementService = scriptManagementService
        self.processor = processor
    }
    
    // MARK: - Core Logic (Data Loading & Reconstruction)
    
    func loadFeedbackData() async {
        self.isLoading = true
        self.currentError = nil
        
        let maxRetries = 2
        defer { self.isLoading = false }
        
        for attempt in 0...maxRetries {
            do {
                async let scriptDataTask = scriptManagementService.fetchScriptWithSentences(id: self.scriptId)
                
                async let summariesTask = scriptManagementService.fetchFeedbackSummaries(forScriptId: self.scriptId)
                async let detailsTask = scriptManagementService.fetchFeedbackDetails(forFeedbackSummaryId: self.targetSummaryId)
                
                let originalScriptData = try await scriptDataTask
                let summaries = try await summariesTask.sorted(by: { $0.createdAt < $1.createdAt })
                let feedbackDetails = try await detailsTask
                
                guard let index = summaries.firstIndex(where: { $0.id == self.targetSummaryId }),
                      let summary = summaries[safe: index] else {
                    throw AppError.dataNotFound("Summary ID \(self.targetSummaryId)에 해당하는 Summary를 찾을 수 없습니다.")
                }
                
                let calculatedFeedbackNumber = index + 1
                
                self.resultModel = self.processor.reconstructResult(
                    fromHistory: summary,
                    scriptTitle: originalScriptData.script.title,
                    feedbackNumber: calculatedFeedbackNumber,
                    details: feedbackDetails,
                    sentences: originalScriptData.sentences
                )
                
                self.currentError = nil
                return
                
            } catch {
                let appError = error.toAppError()
                
                if !appError.isRetryable || attempt == maxRetries {
                    self.currentError = appError
                    return
                }
                
                let delaySeconds = UInt64(pow(2, Double(attempt)))
                try? await Task.sleep(nanoseconds: delaySeconds * 1_000_000_000)
            }
        }
    }
}
