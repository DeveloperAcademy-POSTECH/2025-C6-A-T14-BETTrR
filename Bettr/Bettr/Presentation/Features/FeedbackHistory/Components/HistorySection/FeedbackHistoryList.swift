//
//  FeedbackHistoryList.swift
//  Bettr
//
//  Created by 길정수 on 11/20/25.
//

import SwiftUI

struct FeedbackHistoryList: View {
    let viewModel: FeedbackHistoryViewModel
    
    private var allFeedbackSummaries: [FeedbackSummary] {
        viewModel.feedbackHistoryData?.allFeedbackSummaries ?? []
    }
    private var scriptTitle: String {
        viewModel.currentTitle
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 36) {
                ForEach(allFeedbackSummaries) { feedback in
                    FeedbackHistoryRow(feedback: feedback)
                }
            }
            .padding(.top, 12)
            .padding(.horizontal, 16)
        }
        .scrollIndicators(.hidden)
    }
}
