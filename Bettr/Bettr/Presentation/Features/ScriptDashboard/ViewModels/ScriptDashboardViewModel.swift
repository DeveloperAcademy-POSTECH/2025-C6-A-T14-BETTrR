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
    
    // MARK: - State (뷰에서 사용될 상태)
    
    // 원본 데이터 (새로운 모델 타입으로 정확히 지정됨)
    var scriptDashboardData: ScriptDashboardModel?
    
    // 제목
    var currentTitle: String = "Loading..." {
        didSet {
            handleTitleChange(oldValue: oldValue, newValue: currentTitle)
        }
    }
    
    // 로딩 상태
    var isLoading = false
    
    // 오류 상태
    var showingError = false
    var errorMessage = ""
    
    // MARK: - Init
    
    init(
        scriptId: Int64,
        scriptService: ScriptManagementServiceProtocol,
        dataProcessor: ScriptDashboardDataProcessor = ScriptDashboardDataProcessor()
    ) {
        self.scriptId = scriptId
        self.scriptService = scriptService
        self.dataProcessor = dataProcessor
    }
    
    // MARK: - Public Methods (View's Lifecycle)
    
    @MainActor
    func onAppear() {
        // 뷰가 나타날 때 데이터를 비동기로 로드
        Task {
            await loadDashboardData()
        }
    }
    
    func updateLocalModelTitle(_ newTitle: String) {
        self.scriptDashboardData?.title = newTitle
    }
    
    // MARK: - Private Methods (Internal Logic)
    
    @MainActor
    private func loadDashboardData() async {
        self.isLoading = true
        self.showingError = false
        self.errorMessage = ""
        
        let scriptId = self.scriptId
        
        Task.detached(priority: .userInitiated) {
            do {
                guard let (fetchedScript, fetchedSentences) = try await self.scriptService.fetchScriptWithSentences(id: scriptId) else {
                    throw ScriptRepositoryError.notFound(message: "Script with ID \(scriptId) not found.")
                }
                
                let allFeedbacks = try await self.scriptService.fetchFeedbackSummaries(forScriptId: scriptId)
                let sortedFeedbacks = allFeedbacks.sorted { $0.createdAt > $1.createdAt }
                let recentFeedbacks = Array(sortedFeedbacks.prefix(5))
                
                let recentDetails = try await self.fetchRecentDetails(from: recentFeedbacks)
                
                let statsModel = await self.dataProcessor.processDashboardStats(
                    from: allFeedbacks,
                    recentDetails: recentDetails
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
                }
                
            } catch {
                let error = error
                await MainActor.run {
                    self.errorMessage = "스크립트 로딩 중 오류 발생: \(error.localizedDescription)"
                    self.showingError = true
                    self.isLoading = false
                    self.currentTitle = "스크립트 오류"
                }
            }
        }
    }
    
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
