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
            
        } catch let error as ScriptRepositoryError where error.isNotFoundError {
            // 1. 서비스/레포지토리에서 DataNotFound 에러가 발생한 경우
            print("피드백 상세 정보 불러오기 실패 (DataNotFound): \(error)")
            self.loadError = .dataNotFound("과거 피드백 데이터를 찾는 데 실패했습니다. (원본 스크립트 또는 피드백 상세 정보를 찾을 수 없습니다.)")
            self.isLoading = false
        } catch {
            // 2. 그 외 일반적인 에러 (네트워크 등)
            print("피드백 상세 정보 불러오기 실패: \(error)")
            self.loadError = .networkError(error.localizedDescription)
            self.isLoading = false
        }
    }
}
