//
//  ScriptDashboardViewModel.swift
//  Bettr
//
//  Created by 길정수 on 11/4/25.
//

import Foundation

@Observable
class ScriptDashboardViewModel {
    
    // MARK: - Dependencies (의존성)
    let scriptId: Int64
    private let scriptService: ScriptManagementServiceProtocol
    
    // MARK: - State (뷰에서 사용될 상태)
    
    // 원본 데이터 (새로운 모델 타입으로 정확히 지정됨)
    var scriptDashboardData: ScriptDashboardModel?

    // 로딩 상태
    var isLoading = false
    
    // 오류 상태
    var showingError = false
    var errorMessage = ""
    
    // MARK: - Init
    
    init(
        scriptId: Int64,
        scriptService: ScriptManagementServiceProtocol
    ) {
        self.scriptId = scriptId
        self.scriptService = scriptService
    }
    
    // MARK: - Public Methods (View's Lifecycle)
    
    @MainActor
    func onAppear() {
        // 뷰가 나타날 때 데이터를 비동기로 로드
        Task {
            self.isLoading = true
            await loadDashboardData()
        }
    }
    
    // MARK: - Private Methods (Internal Logic)
    
    @MainActor
    private func loadDashboardData() async {
        defer {
            isLoading = false
        }
        
        do {
            async let scriptDataResult = scriptService.fetchScriptWithSentences(id: scriptId)
            async let feedbackDataResult = scriptService.fetchFeedbackSummaries(forScriptId: scriptId)
            
            guard let fetchedScriptData = try await scriptDataResult else {
                            errorMessage = "스크립트를 불러오는데 실패했습니다: \(scriptId)번 스크립트를 찾을 수 없습니다."
                            showingError = true
                            return
                        }
            
            let fetchedFeedbackData = try await feedbackDataResult
            
            let sentenceModelList = fetchedScriptData.sentences.map { sentence in
                ScriptDashboardSentenceModel(
                    id: sentence.id,
                    orderIndex: sentence.orderIndex,
                    englishText: sentence.englishText
                )
            }
            
            let feedbackModelList = fetchedFeedbackData.map { summary in
                ScriptDashboardFeedbackModel(
                    id: summary.id,
                    totalScore: summary.totalScore,
                    missingWordCount: summary.missingWordCount,
                    addedWordCount: summary.addedWordCount,
                    replacedWordCount: summary.replacedWordCount,
                    practiceDuration: summary.practiceDuration,
                    createdAt: summary.createdAt
                )
            }
            
            self.scriptDashboardData = ScriptDashboardModel(
                title: fetchedScriptData.script.title,
                sentences: sentenceModelList,
                feedbacks: feedbackModelList
            )
            
        } catch {
            errorMessage = "스크립트 로딩 중 오류 발생: \(error.localizedDescription)"
            showingError = true
        }
    }
}

