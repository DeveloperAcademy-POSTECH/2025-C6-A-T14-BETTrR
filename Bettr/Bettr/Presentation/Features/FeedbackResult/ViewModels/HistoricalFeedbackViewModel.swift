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
    var loadError: Error?
    
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
            loadError = NSError(domain: "HistoricalFeedbackViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "FeedbackSummary ID가 없습니다."])
            isLoading = false
            return
        }
        
        self.isLoading = true
        self.loadError = nil
        
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
            
            self.isLoading = false
            
        } catch {
            print("피드백 상세 정보 불러오기 실패: \(error)")
            self.loadError = error
            self.isLoading = false
        }
    }
}
