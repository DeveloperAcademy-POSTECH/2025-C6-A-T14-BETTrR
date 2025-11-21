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
    
    // MARK: - 1. UI State Properties
    var isLoading = true
    var currentError: AppError? = nil
    
    // MARK: - 2. View-Specific Logic Properties
    var resultModel: FeedbackResultModel?
    
    // MARK: - 4. Private Properties & Dependencies
    private let scriptId: Int64
    private let targetSummaryId: Int64
    private let scriptManagementService: ScriptManagementServiceProtocol
    private let processor: FeedbackResultProcessor
    
    // MARK: - 5. Initializer
    
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
    
    // MARK: - 6. Core Logic (Data Loading & Reconstruction)
    
    func loadFeedbackData() async {
            self.isLoading = true
            self.currentError = nil
            
            let maxRetries = 2
            defer { self.isLoading = false }
            
            for attempt in 0...maxRetries {
                do {
                    // 1. Script와 Sentences를 먼저 조회합니다. (ScriptId 활용)
                    async let scriptDataTask = scriptManagementService.fetchScriptWithSentences(id: self.scriptId)
                    
                    // 2. Summary 리스트와 Details를 조회합니다.
                    async let summariesTask = scriptManagementService.fetchFeedbackSummaries(forScriptId: self.scriptId)
                    async let detailsTask = scriptManagementService.fetchFeedbackDetails(forFeedbackSummaryId: self.targetSummaryId)
                    
                    let originalScriptData = try await scriptDataTask
                    let summaries = try await summariesTask.sorted(by: { $0.createdAt < $1.createdAt }) // 생성일 기준 오름차순 정렬 (1번째, 2번째... 순서 계산을 위함)
                    let feedbackDetails = try await detailsTask
                    
                    // 3. targetSummaryId에 해당하는 Summary와 순서를 찾습니다. (필수)
                    guard let index = summaries.firstIndex(where: { $0.id == self.targetSummaryId }),
                          let summary = summaries[safe: index] else {
                        throw AppError.dataNotFound("Summary ID \(self.targetSummaryId)에 해당하는 Summary를 찾을 수 없습니다.")
                    }
                    
                    let calculatedFeedbackNumber = index + 1
                    
                    // 4. Model 재구성
                    self.resultModel = self.processor.reconstructResult(
                        fromHistory: summary,
                        scriptTitle: originalScriptData.script.title,
                        feedbackNumber: calculatedFeedbackNumber,
                        details: feedbackDetails,
                        sentences: originalScriptData.sentences
                    )
                    
                    self.currentError = nil
                    return // 성공 시 종료
                    
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
