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
    
    private var allFeedbackSummaries: [FeedbackSummary] {
        viewModel.feedbackHistoryData?.allFeedbackSummaries ?? []
    }
    
    private var feedbackCount: Int {
        viewModel.feedbackHistoryData?.feedbackCount ?? 0
    }
    
    var body: some View {
        Group {
            if allFeedbackSummaries.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    FeedbackHistoryListTitle(feedbackCount: feedbackCount)
                    EmptyFeedbackView()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        FeedbackHistoryListTitle(feedbackCount: feedbackCount)
                        FeedbackHistoryList(viewModel: viewModel)
                            .padding(.horizontal, 16)
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
        .frame(minWidth: 330)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .cardBordered(padding: 36)
    }
}

struct EmptyFeedbackView: View {
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

struct FeedbackHistoryListTitle: View {
    let feedbackCount: Int
    
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text("피드백 히스토리")
                .font(.subbodyBold24)
                .padding(8)
            
            Text("총 \(feedbackCount)회")
                .font(.calloutRegular16)
                .padding(8)
        }
        .foregroundStyle(.normalBlack900)
        .fixedSize(horizontal: true, vertical: false)
    }
}
