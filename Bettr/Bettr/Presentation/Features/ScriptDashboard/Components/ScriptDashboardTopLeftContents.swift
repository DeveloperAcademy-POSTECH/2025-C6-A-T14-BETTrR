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
                    x: .value("Session", point.session),
                    y: .value("Score", point.score)
                )
                .foregroundStyle(.secondaryBlue700)
                .lineStyle(StrokeStyle(lineWidth: 4))
                
                PointMark(
                    x: .value("Session", point.session),
                    y: .value("Score", point.score)
                )
                .symbol {
                    Circle()
                        .fill(.primaryBlue50)
                        .strokeBorder(.secondaryBlue700, lineWidth: 4)
                        .frame(width: 16, height: 16)
                }
                RuleMark(
                    y: .value("Average", averageScore)
                )
                .foregroundStyle(.alertRed01)
                
            }
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
                AxisMarks(position: .leading, values: .automatic(desiredCount: 2)) { value in
                        AxisValueLabel()
                        AxisGridLine()
                        AxisTick()
                }
            }
        }
        .cardFilled()
    }
}
