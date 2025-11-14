//
//  ScriptDashboardDataProcessor.swift
//  Bettr
//
//  Created by 길정수 on 11/14/25.
//

import Foundation

struct ScriptDashboardDataProcessor {
    
    func processDashboardStats(
        from allFeedbacks: [FeedbackSummary],
        recentDetails: [FeedbackDetail],
        recentFeedbackCount: Int
    ) -> ScriptDashboardStats {
        
        let averageDuration = calculateAverageDurationWithOutlierRemoval(from: allFeedbacks)
        let top3Words = processTopIncorrectWords(from: recentDetails)
        
        return ScriptDashboardStats(
            feedbackCount: allFeedbacks.count,
            top3IncorrectWords: top3Words,
            averagePracticeDuration: averageDuration,
            recentFeedbackCount: recentFeedbackCount
        )
    }
    
    // MARK: - Private Helpers
    
    /// FeedbackDetail에서 틀린 단어를 집계하는 헬퍼 함수
    private func processTopIncorrectWords(from details: [FeedbackDetail]) -> [IncorrectWordCount] {
        
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
        
        // Top 3 추출 (튜플 배열로 변환)
        let top3 = Array(sortedWords.prefix(3)).map { IncorrectWordCount(word: $0.key, count: $0.value) }
        
        return top3
    }
    
    /// IQR을 사용해 이상치를 제거한 평균 연습 시간을 계산합니다.
    private func calculateAverageDurationWithOutlierRemoval(from feedbacks: [FeedbackSummary]) -> Double {
        let sortedDurations = feedbacks.map { $0.practiceDuration }.sorted()
        
        guard !sortedDurations.isEmpty else { return 0.0 }
        
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
