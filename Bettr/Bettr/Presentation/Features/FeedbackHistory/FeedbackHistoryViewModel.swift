//
//  FeedbackHistoryViewModel.swift
//  Bettr
//
//  Created by 길정수 on 11/20/25.
//

import Foundation

@Observable
class FeedbackHistoryViewModel: TitleEditableViewModelProtocol{
    
    // MARK: - Dependencies
    let scriptId: Int64
    let scriptService: ScriptManagementServiceProtocol
    
    // MARK: - Properties
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
    
    // MARK: - TitleEditableViewModelProtocol
    
    func updateLocalModelTitle(_ newTitle: String) {
        self.feedbackHistoryData?.title = newTitle
    }
    
    // MARK: - View Actions
    
    @MainActor
    func onAppear() {
        Task {
            await loadFeedbackHistory()
        }
    }
    
    @MainActor
    func retryLoadData() {
        self.feedbackHistoryData = nil
        self.currentTitle = "Loading..."
        Task {
            await loadFeedbackHistory()
        }
    }
    
    // MARK: - Private Methods
    
    @MainActor
    private func loadFeedbackHistory() async {
        self.isLoading = true
        self.currentError = nil
        
        let scriptId = self.scriptId
        let maxRetries = 2
        
        defer { self.isLoading = false }
        
        for attempt in 0...maxRetries {
            do {
                let fetchedData = try await self.scriptService.fetchScriptWithSentences(id: scriptId)
                let script = fetchedData.script
                let sentences = fetchedData.sentences
                
                let scriptTitle = script.title
                let englishLines: [String] = sentences
                    .sorted { $0.orderIndex < $1.orderIndex }
                    .map { $0.englishText }
                
                let fetchedFeedbackSummaries = try await self.scriptService.fetchFeedbackSummaries(forScriptId: scriptId)
                let allFeedbackSummariesSorted = fetchedFeedbackSummaries.sorted { $0.createdAt > $1.createdAt }
                
                let recentFeedbackSummaries = Array(allFeedbackSummariesSorted.prefix(5))
                
                let allFeedbackDetails = try await self.fetchAllFeedbackDetails(from: allFeedbackSummariesSorted)
                
                let frequentlyWrongWords = calculateTopWrongWords(from: allFeedbackDetails)
                
                let feedbackCount = allFeedbackSummariesSorted.count
                
                self.feedbackHistoryData = FeedbackHistoryModel(
                    title: scriptTitle,
                    allFeedbackSummaries: allFeedbackSummariesSorted,
                    recentFeedbackSummaries: recentFeedbackSummaries,
                    frequentlyWrongWords: frequentlyWrongWords,
                    feedbackCount: feedbackCount,
                    scriptSentences: englishLines
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
    
    /// 주어진 FeedbackSummary 목록에 대한 상세 정보를 비동기로 가져옴
    private func fetchAllFeedbackDetails(from feedbackSummaries: [FeedbackSummary]) async throws -> [FeedbackDetail] {
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
    private func calculateTopWrongWords(from details: [FeedbackDetail]) -> [WrongWordCount] {
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
        }.filter { !$0.isEmpty }
        
        let wordCounts = Dictionary(incorrectWords.map { ($0, 1) }, uniquingKeysWith: +)
        
        let sortedWords = wordCounts.sorted { $0.value > $1.value }
        
        let top5 = Array(sortedWords.prefix(5)).map { WrongWordCount(word: $0.key, count: $0.value) }
        
        return top5
    }
}
