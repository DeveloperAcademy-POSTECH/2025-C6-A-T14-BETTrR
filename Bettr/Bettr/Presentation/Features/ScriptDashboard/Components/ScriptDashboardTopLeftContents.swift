//
//  ScriptDashboardTopLeftContents.swift
//  Bettr
//
//  Created by 길정수 on 11/6/25.
//

import SwiftUI
import Charts

struct FeedbackChartDataPoint: Identifiable {
    let id = UUID()
    let session: Int
    let score: Int
}

struct ScriptDashboardTopLeftContents: View {
    let recentFeedbacks: [FeedbackSummary]
    
    // 차트 데이터 계산
    private var chartData: [FeedbackChartDataPoint] {
        return recentFeedbacks.reversed().enumerated().map { (index, feedback) in
            return FeedbackChartDataPoint(
                session: index + 1,
                score: Int(feedback.accuracy * 100)
            )
        }
    }
    
    // 평균 점수 계산
    private var averageScore: Double {
        guard !chartData.isEmpty else { return 0 }
        return Double(chartData.map { $0.score }.reduce(0, +)) / Double(chartData.count)
    }
    
    // 최대값 계산
    private var maxScore: Int {
        chartData.map { $0.score }.max() ?? 0
    }
    
    // Y축 최대값을 동적으로 계산 (20% 여유 공간 추가)
    private var yAxisMax: Double {
        if maxScore == 0 {
            return 10.0
        }
        return Double(maxScore) * 1.7
    }
    
    var body: some View {
        Group {
            Chart(chartData) { point in
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
            .chartLegend(.hidden)
            .chartXScale(domain: 0...(chartData.count + 1))
            .chartYScale(domain: 0...yAxisMax)
            .chartXAxis {
                AxisMarks(values: Array(0...chartData.count)) { value in
                    AxisGridLine()
                    if let sessionNumber = value.as(Int.self) {
                        if sessionNumber != 0 {
                            AxisValueLabel("\(sessionNumber)")
                        }
                    }
                }
            }
            .chartYAxis {
                if maxScore == 0 {
                    AxisMarks(position: .leading, values: [0]) { value in
                        AxisValueLabel()
                        AxisGridLine()
                        AxisTick()
                    }
                } else {
                    AxisMarks(position: .leading, values: .automatic(desiredCount: 2)) { value in
                        AxisValueLabel()
                        AxisGridLine()
                        AxisTick()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: 272)
        .cardFilled()
        .overlay(alignment: .topTrailing) {
            LegendContent()
                .padding(16)
        }
    }
}

struct LegendContent: View {
    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 6) {
                Circle()
                    .fill(.secondaryBlue700)
                    .frame(width: 8, height: 8)
                Text("점수")
                    .font(.footerRegular11)
                    .foregroundStyle(.normalGray600)
            }
            
            HStack(spacing: 6) {
                Circle()
                    .fill(.alertRed01)
                    .frame(width: 8, height: 8)
                Text("평균")
                    .font(.footerRegular11)
                    .foregroundStyle(.normalGray600)
            }
        }
    }
}

// MARK: - Preview

fileprivate struct ChartPreviewData {
    
    static func date(_ daysAgo: Int) -> Date {
        return Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!
    }
    
    static let sampleFeedbacks: [FeedbackSummary] = [
        .init(id: 1, scriptId: 1, accuracy: 0.65, missingWordCount: 5, addedWordCount: 2, replacedWordCount: 1, practiceDuration: 120.5, createdAt: date(5)), // 65점
        .init(id: 2, scriptId: 1, accuracy: 0.72, missingWordCount: 4, addedWordCount: 3, replacedWordCount: 0, practiceDuration: 110.0, createdAt: date(4)), // 72점
        .init(id: 3, scriptId: 1, accuracy: 0.68, missingWordCount: 6, addedWordCount: 1, replacedWordCount: 2, practiceDuration: 130.2, createdAt: date(3)), // 68점
        .init(id: 4, scriptId: 1, accuracy: 0.85, missingWordCount: 2, addedWordCount: 0, replacedWordCount: 1, practiceDuration: 100.0, createdAt: date(2)), // 85점
        .init(id: 5, scriptId: 1, accuracy: 0.91, missingWordCount: 1, addedWordCount: 0, replacedWordCount: 0, practiceDuration: 95.5, createdAt: date(1))  // 91점
    ]
    
    static let singleFeedback: [FeedbackSummary] = [
        .init(id: 1, scriptId: 1, accuracy: 0.80, missingWordCount: 3, addedWordCount: 1, replacedWordCount: 1, practiceDuration: 105.0, createdAt: date(1)) // 80점
    ]
    
    static let emptyFeedbacks: [FeedbackSummary] = []
}

// 4. 프리뷰 프로바이더
#Preview("데이터가 5개인 경우") {
    ScriptDashboardTopLeftContents(recentFeedbacks: ChartPreviewData.sampleFeedbacks)
}

#Preview("데이터가 1개인 경우") {
    ScriptDashboardTopLeftContents(recentFeedbacks: ChartPreviewData.singleFeedback)
}

#Preview("데이터가 없는 경우") {
    ScriptDashboardTopLeftContents(recentFeedbacks: ChartPreviewData.emptyFeedbacks)
}
