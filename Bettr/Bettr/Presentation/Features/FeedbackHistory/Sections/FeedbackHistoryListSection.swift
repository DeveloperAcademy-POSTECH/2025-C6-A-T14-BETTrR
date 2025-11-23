//
//  FeedbackHistoryListSection.swift
//  Bettr
//
//  Created by 길정수 on 11/20/25.
//


import SwiftUI
import Charts

struct FeedbackHistoryListSection: View {
    let viewModel: FeedbackHistoryViewModel
    
    private var summaries: [FeedbackSummary] {
        viewModel.feedbackHistoryData?.allFeedbackSummaries ?? []
    }
    
    private var feedbackCount: Int {
        viewModel.feedbackHistoryData?.feedbackCount ?? 0
    }
    
    var body: some View {
        TitledSection(
            title: "피드백 히스토리",
            subtitle: "총 \(feedbackCount)회",
            spacing: summaries.isEmpty ? 16 : 4
        ) {
            if summaries.isEmpty {
                EmptyFeedbackView()
            } else {
                FeedbackHistoryList(viewModel: viewModel)
            }
        }
        .frame(minWidth: 330)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .cardBordered(padding: 36)
    }
}

private struct EmptyFeedbackView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Text("피드백이 없어 히스토리를 확인할 수 없습니다")
                .font(.calloutRegular16)
                .foregroundStyle(.normalGray600)
            
            Text("테스트를 통해 피드백을 생성해보세요")
                .font(.calloutRegular16)
                .foregroundStyle(.normalGray600)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
