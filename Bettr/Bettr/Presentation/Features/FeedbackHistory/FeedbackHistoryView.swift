//
//  FeedbackHistoryView.swift
//  Bettr
//
//  Created by 길정수 on 11/20/25.
//

import SwiftUI
import Charts

struct FeedbackHistoryView: View {
    
    let viewModel: FeedbackHistoryViewModel
    
    //    init(viewModel: ScriptDashboardViewModel) {
    //        _viewModel = State(initialValue: viewModel)
    //    }
    
    var body: some View {
        Group {
            if viewModel.isLoading { // 로딩
                ProgressView()
            } else if let error = viewModel.currentError { // 에러
                ErrorView(error: error) {
                    Task { // 다시 시도
                        viewModel.retryLoadData()
                    }
                }
            } else if let data = viewModel.feedbackHistoryData { // 성공
                ScrollView {
                    HStack(spacing: 16) {
                        FeedbackHistoryLeftContents(viewModel: viewModel)
                        FeedbackHistoryRightContents(viewModel: viewModel)
                    }
                    .safeAreaPadding(.horizontal, 84)
                }
            } else { // 예외 케이스: 로딩도 아니고, 에러도 아닌데, 데이터도 없는 경우
                ErrorView(error: .unknown("데이터를 불러오지 못했습니다.")) {
                    Task {
                        viewModel.retryLoadData()
                    }
                }
            }
        }
        .safeAreaPadding(.top, 24)
        .safeAreaPadding(.bottom, 48)
        .navigationBarTitleDisplayMode(.inline)
        .cancelToolbar()
        .onAppear {
            viewModel.onAppear()
        }
    }
}

// MARK: - 왼쪽

struct FeedbackHistoryLeftContents: View {
    let viewModel: FeedbackHistoryViewModel
    
    private var allFeedbackSummaries: [FeedbackSummary] {
        viewModel.feedbackHistoryData?.allFeedbackSummaries ?? []
    }
    
    private var frequentlyWrongWords: [WrongWordCount] {
        viewModel.feedbackHistoryData?.frequentlyWrongWords ?? []
    }
    
    var body: some View {
        VStack(spacing: 60) {
            AccuracyGraphSection(allFeedbackSummaries: allFeedbackSummaries)
            FrequentlyWrongWordsSection(frequentlyWrongWords: frequentlyWrongWords)
        }
    }
}

//import Charts
//
//struct FeedbackChartDataPoint: Identifiable {
//    let id = UUID()
//    let session: Int
//    let score: Int
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
        VStack(spacing: 16) {
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
            .frame(maxWidth: .infinity, maxHeight: 272)
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

struct FrequentlyWrongWordsSection: View {
    let frequentlyWrongWords: [WrongWordCount]
    
    var displayWords: [String] {
        let maxCount = 5
        
        // 데이터에서 단어 문자열만 추출
        let actualWords = frequentlyWrongWords.map { $0.word }
        
        // 부족한 만큼 "-" 문자열로 채움
        let placeholdersNeeded = max(0, maxCount - actualWords.count)
        let placeholders = Array(repeating: "-", count: placeholdersNeeded)
        
        // 실제 단어와 플레이스홀더를 합쳐서 총 5개의 배열 생성
        return actualWords + placeholders
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("자주 틀린 단어")
                .font(.subbodyBold24)
                .foregroundStyle(.normalBlack900)
                .padding(8)
            
            VStack(spacing: 16) {
                ForEach(displayWords.enumerated(), id: \.offset) { (index, word) in
                    WrongWordRow(ranking: index + 1, word: word)
                }
            }
            .padding(.leading, 24)
        }
    }
}

struct WrongWordRow: View {
    let ranking: Int
    let word: String
    
    var body: some View {
        HStack(spacing: 16) {
            Text("\(ranking)")
                .foregroundStyle(.normalGray600)
            
            Text(word)
                .foregroundStyle(.normalBlack900)
        }
        .font(.subbodyBold24)
    }
}

// MARK: - 오른쪽

struct FeedbackHistoryRightContents: View {
    let viewModel: FeedbackHistoryViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("피드백 히스토리")
                    .font(.subbodyBold24)
                    .padding(8)
                
                FeedbackHistoryList(viewModel: viewModel)
                    .padding(.leading, 16)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .cardBordered(padding: 36)
    }
}

struct FeedbackHistoryList: View {
    let viewModel: FeedbackHistoryViewModel
    
    private var allFeedbackSummaries: [FeedbackSummary] {
        viewModel.feedbackHistoryData?.allFeedbackSummaries ?? []
    }
    private var scriptTitle: String {
        viewModel.currentTitle
    }
    
    var body: some View {
        VStack(spacing: 36) {
            if allFeedbackSummaries.isEmpty {
                VStack {
                    Spacer()
                    
                    Text("피드백이 없어 히스토리를 확인할 수 없습니다")
                        .font(.calloutRegular16)
                        .foregroundStyle(.normalGray600)
                        .padding(10)
                    
                    Text("녹음으로 피드백을 생성해보세요")
                        .font(.calloutRegular16)
                        .foregroundStyle(.normalGray600)
                        .padding(10)
                    
                    Spacer()
                }
            } else {
                VStack(spacing: 36) {
                    
                    let totalFeedbackCount = allFeedbackSummaries.count
                    
                    ForEach(Array(allFeedbackSummaries.enumerated()), id: \.element.id) { (index, feedback) in
                        
                        let specificFeedbackNumber = totalFeedbackCount - index
                        
                        FeedbackSummaryCard(feedback: feedback, scriptTitle: scriptTitle, feedbackNumber: specificFeedbackNumber)
                    }
                }
            }
        }
    }
}
