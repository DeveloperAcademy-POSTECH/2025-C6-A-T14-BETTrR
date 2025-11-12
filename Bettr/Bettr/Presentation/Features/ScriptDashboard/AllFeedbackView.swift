//
//  AllFeedbackView.swift
//  Bettr
//
//  Created by 길정수 on 11/10/25.
//

import SwiftUI

struct AllFeedbackView: View {
    let feedbacks: [FeedbackSummary]
    let scriptTitle: String
    let feedbackNumber: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("모든 피드백")
                .font(.subtitleBold32)
                .foregroundStyle(.normalBlack900)
            
            if feedbacks.count > 0 {
                VStack(spacing: 20) {
                    ForEach(feedbacks, id: \.id) { feedback in
                        FeedbackSummaryCard(feedback: feedback, scriptTitle: scriptTitle, feedbackNumber: feedbackNumber)
                    }
                    Spacer()
                }
                .cardBordered(padding: 36)
            }
            else {
                VStack {
                    Spacer()
                    Text("데이터가 충분하지 않아요")
                        .font(.labelBold16)
                        .foregroundStyle(.normalBlack900)
                    
                    Spacer()
                }
                .cardBordered(padding: 36)
            }
        }
        .padding(.horizontal, 84)
        .padding(.top, 36)
        .padding(.bottom, 48)
    }
}
