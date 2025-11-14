//
//  ScriptDashboardViewModel.swift
//  Bettr
//
//  Created by 길정수 on 11/4/25.
//

import Foundation

@Observable
class ScriptDashboardViewModel: TitleEditableViewModelProtocol {
    
    // MARK: - Dependencies (의존성)
    let scriptId: Int64
    let scriptService: ScriptManagementServiceProtocol
    private let dataProcessor: ScriptDashboardDataProcessor
    
    // MARK: Core Data State (핵심 데이터 상태)
    var scriptDashboardData: ScriptDashboardModel?
    var currentTitle: String = "Loading..." {
        didSet {
            handleTitleChange(oldValue: oldValue, newValue: currentTitle)
        }
    }
    var isLoading = true
    var currentError: AppError? = nil
    
    // MARK: - Initialization
    
    init(
        scriptId: Int64,
        scriptService: ScriptManagementServiceProtocol,
        dataProcessor: ScriptDashboardDataProcessor = ScriptDashboardDataProcessor()
    ) {
        self.scriptId = scriptId
        self.scriptService = scriptService
        self.dataProcessor = dataProcessor
    }
    
    // MARK: - Protocol Conformance
    
    func updateLocalModelTitle(_ newTitle: String) {
        self.scriptDashboardData?.title = newTitle
    }
    
    // MARK: - View Lifecycle
    
    @MainActor
    func onAppear() {
        Task {
            await loadDashboardData()
        }
    }
    
    @MainActor
    func retryLoadData() {
        self.scriptDashboardData = nil
        self.currentTitle = "Loading..."
        Task {
            await loadDashboardData()
        }
    }
    
    // MARK: - Private Methods (Internal Logic)
    
    @MainActor
    private func loadDashboardData() async {
        self.isLoading = true
        self.currentError = nil
        
        let scriptId = self.scriptId
        
        Task.detached(priority: .userInitiated) {
            
            let maxRetries = 2
            
            for attempt in 0...maxRetries {
                do {
                    guard let (fetchedScript, fetchedSentences) = try await self.scriptService.fetchScriptWithSentences(id: scriptId) else {
                        let message = "스크립트를 불러오는데 실패했습니다: \(scriptId)번 스크립트를 찾을 수 없습니다."
                        throw AppError.dataNotFound(message)
                    }
                    
                    let allFeedbacks = try await self.scriptService.fetchFeedbackSummaries(forScriptId: scriptId)
                    let sortedFeedbacks = allFeedbacks.sorted { $0.createdAt > $1.createdAt }
                    
                    let recentFeedbacks = Array(sortedFeedbacks.prefix(5))
                    let recentFeedbackCount = recentFeedbacks.count
                    
                    let recentDetails = try await self.fetchRecentDetails(from: recentFeedbacks)
                    
                    let statsModel = await self.dataProcessor.processDashboardStats(
                        from: allFeedbacks,
                        recentDetails: recentDetails,
                        recentFeedbackCount: recentFeedbackCount
                    )
                    
                    let sentenceModelList = fetchedSentences.map {
                        ScriptDashboardSentenceModel(
                            id: $0.id,
                            orderIndex: $0.orderIndex,
                            englishText: $0.englishText
                        )
                    }
                    
                    await MainActor.run {
                        self.scriptDashboardData = ScriptDashboardModel(
                            title: fetchedScript.title,
                            sentences: sentenceModelList,
                            allFeedbacks: sortedFeedbacks,
                            recentFeedbacks: recentFeedbacks,
                            stats: statsModel
                        )
                        
                        self.currentTitle = fetchedScript.title
                        self.isLoading = false
                        self.currentError = nil
                    }
                    return
                    
                } catch {
                    let appError: AppError
                    if let knownError = error as? AppError {
                        appError = knownError
                    } else {
                        appError = .networkError(error.localizedDescription)
                    }
                    
                    // 재시도 불가능한 에러이거나, 마지막 시도였다면
                    if !appError.isRetryable || attempt == maxRetries {
                        await MainActor.run {
                            self.currentError = appError
                            self.currentTitle = "스크립트 오류"
                            self.isLoading = false
                        }
                        return // [중요] 최종 실패 시 함수(및 루프) 종료
                    }
                    
                    // 아직 재시도 기회 남음 (Exponential Backoff)
                    do {
                        let delaySeconds = UInt64(pow(2, Double(attempt)))
                        try await Task.sleep(nanoseconds: delaySeconds * 1_000_000_000)
                    } catch {
                        // Task.sleep이 취소된 경우 (예: 뷰가 사라져서 Task가 취소됨)
                        await MainActor.run {
                            self.currentError = .unknown("작업이 취소되었습니다.")
                            self.isLoading = false
                        }
                        return
                    }
                }
            }
        }
    }
    
    // MARK: Helper Methods
    private func fetchRecentDetails(from recentFeedbacks: [FeedbackSummary]) async throws -> [FeedbackDetail] {
        return try await withThrowingTaskGroup(
            of: [FeedbackDetail].self,
            returning: [FeedbackDetail].self
        ) { taskGroup in
            
            for summary in recentFeedbacks {
                if let summaryId = summary.id {
                    taskGroup.addTask {
                        return try await self.scriptService.fetchFeedbackDetails(forFeedbackSummaryId: summaryId)
                    }
                }
            }
            
            var detailsList: [FeedbackDetail] = []
            for try await details in taskGroup {
                detailsList.append(contentsOf: details)
            }
            return detailsList
        }
    }
}
