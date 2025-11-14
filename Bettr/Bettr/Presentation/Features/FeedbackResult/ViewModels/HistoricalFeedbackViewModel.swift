//
//  HistoricalFeedbackViewModel.swift
//  Bettr
//
//  Created by 길정수 on 11/5/25.
//

import Foundation

@Observable
class HistoricalFeedbackViewModel {
    
    // MARK: - 1. UI State Properties
    var isLoading = true
    var loadError: AppError? = nil
    
    // MARK: - 2. Display Properties (View Data)
    var resultModel: FeedbackResultModel?
    
    // MARK: - 3. Dependencies & Private Properties
    
    private let summary: FeedbackSummary
    private let scriptManagementService: ScriptManagementServiceProtocol
    private let scriptTitle: String
    private let feedbackNumber: Int
    
    private let processor: FeedbackResultProcessor
    
    // MARK: - 4. Initializer
    
    init(
        summary: FeedbackSummary,
        scriptTitle: String,
        feedbackNumber: Int,
        scriptManagementService: ScriptManagementServiceProtocol,
        processor: FeedbackResultProcessor = FeedbackResultProcessor()
    ) {
        self.summary = summary
        self.scriptManagementService = scriptManagementService
        self.scriptTitle = scriptTitle
        self.feedbackNumber = feedbackNumber
        self.processor = processor
    }
    
    // MARK: - 5. Core Logic (Data Loading & Reconstruction)
    
    func loadFeedbackData() async {
        guard let summaryId = summary.id else {
            let errorMsg = "FeedbackSummary ID가 없습니다."
            self.loadError = .dataNotFound(errorMsg)
            self.isLoading = false
            return
        }
        
        self.isLoading = true
        self.loadError = nil
        
        let maxRetries = 2
        
        defer { self.isLoading = false }
        
        for attempt in 0...maxRetries {
            do {
                async let scriptTask = scriptManagementService.fetchScriptWithSentences(id: summary.scriptId)
                async let detailsTask = scriptManagementService.fetchFeedbackDetails(forFeedbackSummaryId: summaryId)
                
                let originalScriptData = try await scriptTask
                let feedbackDetails = try await detailsTask
                
                self.resultModel = self.processor.reconstructResult(
                    fromHistory: self.summary,
                    scriptTitle: self.scriptTitle,
                    feedbackNumber: self.feedbackNumber,
                    details: feedbackDetails,
                    sentences: originalScriptData.sentences
                )
                
                self.loadError = nil
                return
                
            } catch {
                let appError = error.toAppError()
                
                if !appError.isRetryable || attempt == maxRetries {
                    if case .dataNotFound = appError {
                        self.loadError = .dataNotFound("과거 피드백 데이터를 찾는 데 실패했습니다.")
                    } else {
                        self.loadError = appError
                    }
                    return
                }
                
                let delaySeconds = UInt64(pow(2, Double(attempt)))
                try? await Task.sleep(nanoseconds: delaySeconds * 1_000_000_000)
            }
        }
    }
}
