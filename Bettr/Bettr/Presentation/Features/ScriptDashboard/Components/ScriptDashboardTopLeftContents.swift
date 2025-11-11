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
    let session: Int // X축 (1, 2, 3...)
    let score: Double  // Y축 (totalScore * 100)
}

struct ScriptDashboardTopLeftContents: View {
    var feedbacks: [FeedbackSummary]
    
    // 차트 데이터 계산
    private var chartData: [FeedbackChartDataPoint] {
        feedbacks.enumerated().map { (index, feedback) in
            FeedbackChartDataPoint(session: index + 1, score: feedback.accuracy * 100)
        }
    }
    
    // 평균 점수 계산
    private var averageScore: Double {
        guard !chartData.isEmpty else { return 0 }
        return chartData.map { $0.score }.reduce(0, +) / Double(chartData.count)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            if !feedbacks.isEmpty {
                Chart(chartData) { point in
                    LineMark(
                        x: .value("Session", point.session),
                        y: .value("Score", point.score)
                    )
                    .foregroundStyle(.secondaryBlue700)
                    .interpolationMethod(.monotone)
                    
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
                .chartYScale(domain: 0...100)
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
                    AxisMarks(position: .leading, values: [0, 50]) { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel()
                    }
                }
                .padding(.leading, 20)
                .padding(.bottom, 16)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
            } else {
                VStack {
                    Spacer()
                    Text("데이터가 충분하지 않아요")
                        .font(.labelBold16)
                        .foregroundStyle(.normalBlack900)
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.primaryBlue50)
        )
    }
}
