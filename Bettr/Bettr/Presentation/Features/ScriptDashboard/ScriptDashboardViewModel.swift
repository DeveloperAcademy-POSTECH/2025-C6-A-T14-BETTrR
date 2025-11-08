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
    
    // 제목
    var currentTitle: String = "Loading..." {
        didSet {
            if oldValue != "Loading..." && oldValue != currentTitle {
                self.scriptDashboardData?.title = currentTitle
                saveTitleToDatabase(newTitle: currentTitle)
            }
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
                    throw ScriptRepositoryError.notFound(message: "Script with ID \(scriptId) not found.")
                }
                
                let allFeedbacks = try await self.scriptService.fetchFeedbackSummaries(forScriptId: scriptId)
                
                // 평균 녹음 시간을 계산함
                let averageDuration = await self.calculateAverageDurationWithOutlierRemoval(from: allFeedbacks)
                
                // 최근 5개의 피드백 요약본을 찾음 (View가 아닌 VM에서)
                let sortedFeedbacks = allFeedbacks.sorted { $0.createdAt > $1.createdAt }
                let recentFeedbacks = Array(sortedFeedbacks.prefix(5))
                
                // 최근 5개에 대해서만 상세 내역(Detail)을 가져옴 (N=5회 호출)
                let recentDetails = try await withThrowingTaskGroup(
                    of: [FeedbackDetail].self,
                    returning: [FeedbackDetail].self
                ) { taskGroup in
                    
                    for summary in recentFeedbacks {
                        if let summaryId = summary.id {
                            // 5개의 작업을 그룹에 추가 (바로 실행 시작)
                            taskGroup.addTask {
                                return try await self.scriptService.fetchFeedbackDetails(forFeedbackSummaryId: summaryId)
                            }
                        }
                    }
                    
                    // 그룹의 모든 작업이 끝날 때까지 기다렸다가 결과를 합침
                    var detailsList: [FeedbackDetail] = []
                    for try await details in taskGroup {
                        detailsList.append(contentsOf: details)
                    }
                    return detailsList
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
                        feedbackCount: sortedFeedbacks.count,
                        recentFeedbacks: recentFeedbacks,
                        recentFeedbackCount: recentFeedbacks.count,
                        top3IncorrectWords: top3Words,
                        averagePracticeDuration: averageDuration
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
    
    /// 스크립트 제목을 DB에 저장하기 위한 함수
        private func saveTitleToDatabase(newTitle: String) {
            Task(priority: .background) {
                do {
           //         try await scriptService.updateScriptTitle(id: scriptId, newTitle: newTitle)
                    print("✅ 대시보드 제목 DB 저장 성공: \(newTitle)")
                } catch {
                    print("🔥 대시보드 제목 DB 저장 실패: \(error.localizedDescription)")
                    // (선택) 사용자에게 저장 실패 알림
                }
            }
        }
    
    /// FeedbackDetail에서 틀린 단어를 집계하는 헬퍼 함수
    private func processTopIncorrectWords(from details: [FeedbackDetail]) -> [IncorrectWordCount] {
        
        let incorrectWords = details.compactMap { detail -> String? in
            switch detail.errorType {
            case .missingWord, .replacedWord, .addedWord:
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
    
    /// IQR을 사용해 이상치를 제거한 평균 연습 시간을 계산합니다.
    private func calculateAverageDurationWithOutlierRemoval(from feedbacks: [FeedbackSummary]) -> Double {
        let durations = feedbacks.map { $0.practiceDuration }
        guard !durations.isEmpty else { return 0.0 }
        
        let sortedDurations = durations.sorted()
        let count = sortedDurations.count
        
        // 데이터가 너무 적으면 IQR이 무의미하므로 단순 평균 반환
        guard count >= 4 else {
            return sortedDurations.reduce(0, +) / Double(count)
        }
        
        // 1. Q1(25%)과 Q3(75%) 계산
        let q1 = findQuantile(0.25, in: sortedDurations)
        let q3 = findQuantile(0.75, in: sortedDurations)
        
        // 2. IQR 계산
        let iqr = q3 - q1
        
        // 3. 정상 범위 설정
        let lowerBound = q1 - (1.5 * iqr)
        let upperBound = q3 + (1.5 * iqr)
        
        // 4. 이상치를 제외한 데이터 필터링
        let filteredDurations = sortedDurations.filter { $0 >= lowerBound && $0 <= upperBound }
        
        guard !filteredDurations.isEmpty else {
            // 모든 데이터가 이상치로 판단될 경우, 그냥 단순 평균 반환 (혹은 0.0)
            return sortedDurations.reduce(0, +) / Double(count)
        }
        
        // 5. 최종 평균 계산
        let average = filteredDurations.reduce(0, +) / Double(filteredDurations.count)
        return average
    }
    
    /// 정렬된 배열에서 특정 사분위수(Quantile) 값을 찾습니다. (선형 보간법)
    private func findQuantile(_ q: Double, in sortedData: [Double]) -> Double {
        let n = Double(sortedData.count)
        
        // n-1 방식의 인덱스 계산
        let index = (n - 1) * q
        let lowerIndex = Int(floor(index))
        let upperIndex = Int(ceil(index))
        
        // 인덱스가 정수일 경우
        if lowerIndex == upperIndex {
            return sortedData[lowerIndex]
        }
        
        // 인덱스가 소수일 경우, 두 값 사이를 선형 보간
        let weight = index - Double(lowerIndex)
        return sortedData[lowerIndex] * (1.0 - weight) + sortedData[upperIndex] * weight
    }
}
