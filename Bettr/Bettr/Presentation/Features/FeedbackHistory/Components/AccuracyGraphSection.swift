//
//  AccuracyGraphSection.swift
//  Bettr
//
//  Created by 길정수 on 11/20/25.
//


import SwiftUI
import Charts

struct AccuracyGraphSection: View {
    let allFeedbackSummaries: [FeedbackSummary]
    
    @State private var pageIndex: Int = 0
    private let pageSize = 5
    
    // FeedbackChartDataPoint로 변환
    private var chartData: [FeedbackChartDataPoint] {
        return allFeedbackSummaries.reversed().enumerated().map { (index, feedback) in
            return FeedbackChartDataPoint(
                session: index + 1,
                score: Int(feedback.accuracy * 100)
            )
        }
    }
    
    // 페이지 데이터 계산
    private var pagedChartData: [FeedbackChartDataPoint] {
        guard !chartData.isEmpty else { return [] }
        let chunks = chartData.chunkedFromEnd(into: pageSize)
        if pageIndex < 0 || pageIndex >= chunks.count { return [] }
        return chunks[pageIndex]
    }
    
    // 평균 점수 계산
    private var averageScore: Double {
        guard !chartData.isEmpty else { return 0 }
        return Double(chartData.map { $0.score }.reduce(0, +)) / Double(chartData.count)
    }
    
    // X축 값
    private var xDomain: ClosedRange<Int> {
        guard let minX = pagedChartData.map({ $0.session }).min(),
              let maxX = pagedChartData.map({ $0.session }).max() else { return 0...1 }
        return (minX - 1)...(maxX + 1)
    }
    
    // 최대값 계산
    private var localMaxScore: Int {
        pagedChartData.map { $0.score }.max() ?? 0
    }
    
    // Y축 domain: 최대값/최소값에 여유 공간
    private var yAxisMax: Double {
        let maxScore = pagedChartData.map { $0.score }.max() ?? 0
        let minScore = pagedChartData.map { $0.score }.min() ?? 0
        let padding = max(5, Double(maxScore - minScore) * 0.2) // 20% 여유
        return Double(maxScore) + padding
    }
    
    // 스와이프 제스처
    private var swipeGesture: some Gesture {
        DragGesture()
            .onEnded { value in
                let threshold: CGFloat = 30
                
                // 왼→오: 과거로 이동
                if value.translation.width > threshold {
                    let maxPage = (chartData.count - 1) / pageSize
                    if pageIndex < maxPage {
                        pageIndex += 1
                    }
                }
                
                // 오→왼: 최신으로 이동
                if value.translation.width < -threshold {
                    if pageIndex > 0 {
                        pageIndex -= 1
                    }
                }
            }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            // 타이틀
            Text("종합 점수 추이")
                .font(.subbodyBold24)
                .foregroundStyle(.normalBlack900)
                .padding(8)
            
            // 그래프
            Group {
                Chart(pagedChartData) { point in
                    LineMark(
                        x: .value("회차", point.session),
                        y: .value("점수", point.score)
                    )
                    .lineStyle(StrokeStyle(lineWidth: 4))
                    .foregroundStyle(.secondaryBlue700)
                    
                    PointMark(
                        x: .value("회차", point.session),
                        y: .value("점수", point.score)
                    )
                    .symbol {
                        Circle()
                            .fill(.primaryBlue50)
                            .strokeBorder(.secondaryBlue700, lineWidth: 4)
                            .frame(width: 16, height: 16)
                    }
                    
                    RuleMark(
                        y: .value("평균", averageScore)
                    )
                    .foregroundStyle(.alertRed01)
                }
                .gesture(swipeGesture)
                .chartLegend(.hidden)
                .chartXScale(domain: xDomain)
                .chartYScale(domain: 0...yAxisMax)
                .chartXAxis {
                    AxisMarks(values: pagedChartData.map { $0.session }) { value in
                        AxisGridLine()
                        AxisValueLabel("\(value.as(Int.self) ?? 0)")
                    }
                }
                .animation(.spring(), value: pageIndex)
                .chartYAxis {
                    if localMaxScore == 0 {
                        AxisMarks(position: .leading, values: [0]) { _ in
                            AxisValueLabel()
                            AxisGridLine()
                            AxisTick()
                        }
                    } else {
                        AxisMarks(position: .leading, values: .automatic(desiredCount: 2)) { _ in
                            AxisValueLabel()
                            AxisGridLine()
                            AxisTick()
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: 180)
            .frame(minHeight: 120)
            .cardFilled()
            .overlay(alignment: .topTrailing) {
                if !chartData.isEmpty {
                    LegendContent()
                        .padding(16)
                }
            }
            .overlay(alignment: .center) {
                if chartData.isEmpty {
                    Text("피드백이 없어 그래프를 볼 수 없습니다")
                        .font(.calloutRegular16)
                        .foregroundStyle(.normalGray600)
                }
            }
        }
    }
}
