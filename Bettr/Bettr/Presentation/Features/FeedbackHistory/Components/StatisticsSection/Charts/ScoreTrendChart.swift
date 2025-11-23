//
//  ScoreTrendChart.swift
//  Bettr
//
//  Created by 길정수 on 11/20/25.
//

import SwiftUI
import Charts

struct ScoreTrendChart: View {
    let summaries: [FeedbackSummary]
    
    @State private var viewModel: ScoreTrendViewModel
    
    init(allFeedbackSummaries: [FeedbackSummary]) {
        self.summaries = allFeedbackSummaries
        _viewModel = State(initialValue: ScoreTrendViewModel(summaries: allFeedbackSummaries))
    }
    
    var body: some View {
        Chart(viewModel.pagedChartData) { point in
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
                y: .value("평균", viewModel.averageScore)
            )
            .foregroundStyle(.alertRed01)
        }
        .chartLegend(.hidden)
        .chartXScale(domain: viewModel.xDomain)
        .chartYScale(domain: 0...viewModel.yAxisMax)
        .chartXAxis {
            AxisMarks(values: viewModel.pagedChartData.map { $0.session }) { value in
                AxisGridLine()
                AxisValueLabel("\(value.as(Int.self) ?? 0)")
            }
        }
        .chartYAxis {
            if viewModel.localMaxScore == 0 {
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
        .frame(minHeight: 120, maxHeight: 180)
        .frame(maxWidth: .infinity)
        .cardFilled()
        .gesture(
            DragGesture()
                .onEnded { value in
                    withAnimation(.spring()) {
                        viewModel.handleSwipe(translationWidth: value.translation.width)
                    }
                }
        )
        .overlay(alignment: .topTrailing) {
            if !viewModel.chartData.isEmpty {
                Legend().padding(16)
            }
        }
        .overlay(alignment: .center) {
            if viewModel.chartData.isEmpty {
                Text("피드백이 없어 그래프를 볼 수 없습니다")
                    .font(.calloutRegular16)
                    .foregroundStyle(.normalGray600)
            }
        }
        .onChange(of: summaries) { _, newValue in
            viewModel.updateData(newValue)
        }
    }
}

private extension ScoreTrendChart {
    struct Legend: View {
        var body: some View {
            HStack(spacing: 12) {
                ChartLegendItem(color: .secondaryBlue700, text: "점수")
                ChartLegendItem(color: .alertRed01, text: "평균")
            }
        }
    }
}
