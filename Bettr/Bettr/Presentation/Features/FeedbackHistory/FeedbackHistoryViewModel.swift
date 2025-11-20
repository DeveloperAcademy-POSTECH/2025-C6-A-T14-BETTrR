//
//  FeedbackHistoryViewModel.swift
//  Bettr
//
//  Created by 길정수 on 11/20/25.
//

import Foundation

@Observable
class FeedbackHistoryViewModel {
    
    // MARK: - Dependencies (의존성)
    let scriptId: Int64
    let scriptService: ScriptManagementServiceProtocol
    
    // MARK: Core Data State (핵심 데이터 상태)
    var feedbackHistoryData: FeedbackHistoryModel?
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
    ) {
        self.scriptId = scriptId
        self.scriptService = scriptService
    }
    
    // MARK: - Protocol Conformance
    
    func updateLocalModelTitle(_ newTitle: String) {
        self.feedbackHistoryData?.title = newTitle
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
        self.feedbackHistoryData = nil
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
        let maxRetries = 2
        
        defer { self.isLoading = false }
        
        for attempt in 0...maxRetries {
            do {
                let fetchedScript = try await self.scriptService.fetchScript(id: scriptId)
                
                guard let script = fetchedScript else {
                    throw AppError.dataNotFound("스크립트를 찾을 수 없습니다.")
                }
                
                let scriptTitle = script.title
                
                let fetchedFeedbackSummaries = try await self.scriptService.fetchFeedbackSummaries(forScriptId: scriptId)
                let allFeedbackSummariesSorted = fetchedFeedbackSummaries.sorted { $0.createdAt > $1.createdAt }
                
                let recentFeedbackSummaries = Array(allFeedbackSummariesSorted.prefix(5))
                
                let allFeedbackDetails = try await self.fetchRecentDetails(from: allFeedbackSummariesSorted)

                let frequentlyWrongWords = processFrequentlyWrongWords(from: allFeedbackDetails)
                
                self.feedbackHistoryData = FeedbackHistoryModel(
                    title: scriptTitle,
                    allFeedbackSummaries: allFeedbackSummariesSorted,
                    recentFeedbackSummaries: recentFeedbackSummaries,
                    frequentlyWrongWords: frequentlyWrongWords
                )
                
                self.currentTitle = scriptTitle
                self.currentError = nil
                return
                
            } catch {
                let appError = error.toAppError()
                print("피드백 데이터 로드 실패 (시도 \(attempt + 1)): \(appError.userFriendlyMessage)")
                
                if !appError.isRetryable || attempt == maxRetries {
                    if case .dataNotFound = appError {
                        self.currentTitle = "스크립트 없음"
                    } else {
                        self.currentTitle = "스크립트 오류"
                    }
                    self.currentError = appError
                    return
                }
                
                do {
                    let delaySeconds = UInt64(pow(2, Double(attempt)))
                    try await Task.sleep(nanoseconds: delaySeconds * 1_000_000_000)
                } catch {
                    self.currentError = .unknown("작업이 취소되었습니다.")
                    return
                }
            }
        }
    }
    
    // MARK: - Private Helpers
    
    private func fetchRecentDetails(from feedbackSummaries: [FeedbackSummary]) async throws -> [FeedbackDetail] {
        return try await withThrowingTaskGroup(
            of: [FeedbackDetail].self,
            returning: [FeedbackDetail].self
        ) { taskGroup in
            
            for summary in feedbackSummaries {
                if let summaryId = summary.id {
                    taskGroup.addTask {
                        return try await self.scriptService.fetchFeedbackDetails(forFeedbackSummaryId: summaryId)
                    }
                }
            }
            
            return try await taskGroup.reduce(into: [FeedbackDetail]()) { accumulator, details in
                accumulator.append(contentsOf: details)
            }
        }
    }
    
    /// FeedbackDetail에서 틀린 단어를 집계하는 헬퍼 함수
    private func processFrequentlyWrongWords(from details: [FeedbackDetail]) -> [WrongWordCount] {
        
        let incorrectWords = details.compactMap { detail -> String? in
            switch detail.wordDiff {
            case .missing(let expected):
                return expected
                    .lowercased()
                    .trimmingCharacters(in: .punctuationCharacters)
            case .replaced(let expected, _):
                return expected
                    .lowercased()
                    .trimmingCharacters(in: .punctuationCharacters)
            case .extra(let actual):
                return actual
                    .lowercased()
                    .trimmingCharacters(in: .punctuationCharacters)
            case .matched:
                return nil
            }
        }.filter { !$0.isEmpty } // 빈 문자열 제거
        
        // 단어별 빈도수 계산
        let wordCounts = Dictionary(incorrectWords.map { ($0, 1) }, uniquingKeysWith: +)
        
        // 횟수(value) 기준으로 내림차순 정렬
        let sortedWords = wordCounts.sorted { $0.value > $1.value }
        
        // Top 5 추출 (튜플 배열로 변환)
        let top5 = Array(sortedWords.prefix(5)).map { WrongWordCount(word: $0.key, count: $0.value) }
        
        return top5
    }
}
