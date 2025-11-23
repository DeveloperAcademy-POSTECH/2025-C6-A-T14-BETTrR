//
//  ScoreTrendChartViewModel.swift
//  Bettr
//
//  Created by 길정수 on 11/23/25.
//

import Foundation

@Observable
final class ScoreTrendViewModel {
    private let pageSize = 5
    
    var pageIndex: Int = 0
    
    private var allFeedbackSummaries: [FeedbackSummary] = []
    
    var chartData: [ScoreTrendDataPoint] = []
    
    init(summaries: [FeedbackSummary]) {
        self.updateData(summaries)
    }
    
    /// 외부에서 데이터가 변경되었을 때 호출하여 차트 데이터를 갱신합니다.
    func updateData(_ summaries: [FeedbackSummary]) {
        self.allFeedbackSummaries = summaries
        self.chartData = summaries.reversed().enumerated().map { (index, feedback) in
            ScoreTrendDataPoint(
                session: index + 1,
                score: Int(feedback.accuracy * 100)
            )
        }
    }
    
    /// 현재 페이지에 보여줄 데이터
    var pagedChartData: [ScoreTrendDataPoint] {
        guard !chartData.isEmpty else { return [] }
        let chunks = chartData.chunkedFromEnd(into: pageSize)
        
        if pageIndex < 0 || pageIndex >= chunks.count { return [] }
        return chunks[pageIndex]
    }
    
    /// 현재 페이지의 평균 점수
    var averageScore: Double {
        guard !chartData.isEmpty else { return 0 }
        return Double(chartData.map { $0.score }.reduce(0, +)) / Double(chartData.count)
    }
    
    /// X축 범위
    var xDomain: ClosedRange<Int> {
        guard let minX = pagedChartData.map({ $0.session }).min(),
              let maxX = pagedChartData.map({ $0.session }).max() else { return 0...1 }
        return (minX - 1)...(maxX + 1)
    }
    
    /// Y축 최대값 (여유 공간 포함)
    var yAxisMax: Double {
        let maxScore = pagedChartData.map { $0.score }.max() ?? 0
        let minScore = pagedChartData.map { $0.score }.min() ?? 0
        let padding = max(5, Double(maxScore - minScore) * 0.2)
        return Double(maxScore) + padding
    }
    
    /// Y축 그리드 결정을 위한 로컬 최대값
    var localMaxScore: Int {
        pagedChartData.map { $0.score }.max() ?? 0
    }
        
    /// 스와이프 제스처 처리
    func handleSwipe(translationWidth: CGFloat) {
        let threshold: CGFloat = 30
        
        // 왼 → 오: 과거로 이동
        if translationWidth > threshold {
            let maxPage = (chartData.count - 1) / pageSize
            if pageIndex < maxPage {
                pageIndex += 1
            }
        }
        
        // 오 → 왼: 최신으로 이동
        if translationWidth < -threshold {
            if pageIndex > 0 {
                pageIndex -= 1
            }
        }
    }
}
