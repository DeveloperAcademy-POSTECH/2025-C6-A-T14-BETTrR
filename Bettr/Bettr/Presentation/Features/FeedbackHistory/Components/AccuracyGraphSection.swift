//
//  AccuracyGraphSection.swift
//  Bettr
//
//  Created by 길정수 on 11/20/25.
//


import SwiftUI
import Charts

//
//struct FeedbackChartDataPoint: Identifiable {
//    let id = UUID()
//    let session: Int
//    let score: Int
//}

//struct LegendContent: View {
//    var body: some View {
//        HStack(spacing: 12) {
//            HStack(spacing: 6) {
//                Circle()
//                    .fill(.secondaryBlue700)
//                    .frame(width: 8, height: 8)
//                Text("점수")
//                    .font(.footerRegular11)
//                    .foregroundStyle(.normalGray600)
//            }
//
//            HStack(spacing: 6) {
//                Circle()
//                    .fill(.alertRed01)
//                    .frame(width: 8, height: 8)
//                Text("평균")
//                    .font(.footerRegular11)
//                    .foregroundStyle(.normalGray600)
//            }
//        }
//    }
//}

struct AccuracyGraphSection: View {
    let allFeedbackSummaries: [FeedbackSummary]
    
    private var chartData: [FeedbackChartDataPoint] {
        return allFeedbackSummaries.reversed().enumerated().map { (index, feedback) in
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
        VStack(alignment: .leading, spacing: 16) {
            Text("종합 점수 추이")
                .font(.subbodyBold24)
                .foregroundStyle(.normalBlack900)
                .padding(8)
            
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
