//
//  FeedbackHistoryList.swift
//  Bettr
//
//  Created by 길정수 on 11/20/25.
//


import SwiftUI
import Charts

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
