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
            await loadDashboardData()
        }
    }
    
    // MARK: - Private Methods (Internal Logic)
    
    @MainActor
        private func loadDashboardData() async {
            self.isLoading = true
            self.showingError = false
            self.errorMessage = ""
            
            let scriptId = self.scriptId // background task에서 사용하기 위해 캡처
            
            Task.detached(priority: .userInitiated) {
                do {
                    // 스크립트와 모든 피드백 요약본(Summary)을 가져옴 (동기)
                    guard let (fetchedScript, fetchedSentences) = try await self.scriptService.fetchScriptWithSentences(id: scriptId) else {
                        // ScriptRepositoryError 같은 적절한 에러를 throw
                        throw URLError(.badURL) // 예시 에러
                    }
                    
                    let allFeedbacks = try await self.scriptService.fetchFeedbackSummaries(forScriptId: scriptId)
                    
                    // 최근 5개의 피드백 요약본을 찾음 (View가 아닌 VM에서)
                    let sortedFeedbacks = allFeedbacks.sorted { $0.createdAt > $1.createdAt }
                    let recentFeedbacks = sortedFeedbacks.prefix(5)
                    
                    // 최근 5개에 대해서만 상세 내역(Detail)을 가져옴 (N=5회 호출)
                    var recentDetails: [FeedbackDetail] = []
                    for summary in recentFeedbacks {
                        if let summaryId = summary.id {
                            // 5번의 동기 DB 호출 (백그라운드 스레드이므로 괜찮음)
                            let details = try await self.scriptService.fetchFeedbackDetails(forFeedbackSummaryId: summaryId)
                            recentDetails.append(contentsOf: details)
                        }
                    }
                    
                    // 가져온 상세 내역을 기반으로 Top 3 단어 집계
                    let top3Words = await self.processTopIncorrectWords(from: recentDetails)
                    
                    let sentenceModelList = fetchedSentences.map {
                        ScriptDashboardSentenceModel(
                            id: $0.id,
                            orderIndex: $0.orderIndex,
                            englishText: $0.englishText
                        )
                    }
                    
                    // 모든 데이터가 준비되면 MainActor(UI 스레드)로 전환하여 UI 상태 업데이트
                    await MainActor.run {
                        self.scriptDashboardData = ScriptDashboardModel(
                            title: fetchedScript.title,
                            sentences: sentenceModelList,
                            feedbacks: allFeedbacks,      // 뷰에는 모든 피드백 전달
                            top3IncorrectWords: top3Words // 계산된 Top 3 전달
                        )
                        self.isLoading = false
                    }
                    
                } catch {
                    // 에러 발생 시 MainActor에서 에러 상태 업데이트
                    let error = error // 캡처
                    await MainActor.run {
                        self.errorMessage = "스크립트 로딩 중 오류 발생: \(error.localizedDescription)"
                        self.showingError = true
                        self.isLoading = false
                    }
                }
            }
        }
        
        /// FeedbackDetail에서 틀린 단어를 집계하는 헬퍼 함수
        private func processTopIncorrectWords(from details: [FeedbackDetail]) -> [IncorrectWordCount] {
            
            let incorrectWords = details.compactMap { detail -> String? in
                switch detail.errorType {
                case .missingWord, .replacedWord, .addedWord:
                    // 누락되거나 대체된 단어는 원본 텍스트(originalText)를 집계
                    return detail.originalText?
                        .lowercased()
                        .trimmingCharacters(in: .punctuationCharacters) // 구두점 제거
                }
            }.filter { !$0.isEmpty } // 빈 문자열 제거
            
            // 단어별 빈도수 계산
            let wordCounts = Dictionary(incorrectWords.map { ($0, 1) }, uniquingKeysWith: +)
            
            // 횟수(value) 기준으로 내림차순 정렬
            let sortedWords = wordCounts.sorted { $0.value > $1.value }
            
            // Top 3 추출 (튜플 배열로 변환)
            let top3 = Array(sortedWords.prefix(3)).map { IncorrectWordCount(word: $0.key, count: $0.value) }
            
            return top3
        }
    }

