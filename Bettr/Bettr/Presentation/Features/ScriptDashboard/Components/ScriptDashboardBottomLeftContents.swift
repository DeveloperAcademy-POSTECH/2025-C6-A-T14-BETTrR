//
//  ScriptDashboardBottomLeftContents.swift
//  Bettr
//
//  Created by 길정수 on 11/6/25.
//

import SwiftUI

struct ScriptDashboardBottomLeftContents: View {
    @Environment(NavigationRouter.self) var router
    @Environment(\.metrics) var metrics
    
    var recentFeedbacks: [FeedbackSummary]
    var allFeedbacks: [FeedbackSummary]
    let scriptTitle: String
    let feedbackNumber: Int
        
    var body: some View {
        
        VStack(spacing: 8) {
            HStack {
                Text("최근 생성된 피드백")
                    .font(.system(size: metrics.font24, weight: .bold))
                
                Spacer()
                
                if allFeedbacks.count > 5 {
                    Button(action: {
                        router.push(Route.allFeedback(feedbacks: allFeedbacks, scriptTitle: scriptTitle, feedbackNumber: feedbackNumber))
                    }) {
                        HStack(spacing: 4) {
                            Text("더보기")
                            Image(systemName: "chevron.right")
                        }
                        .font(.system(size: metrics.font14, weight: .regular))
                    }
                }
            }
            .padding(8)
            .foregroundStyle(.normalBlack900)
            
            VStack(spacing: metrics.listSpacing) {
                if recentFeedbacks.isEmpty {
                    VStack(spacing: metrics.listSpacing) {
                        ForEach(0..<5, id: \.self) { _ in
                            FeedbackSummaryCardPlaceholderView()
                        }
                        Spacer()
                    }
                    .overlay(
                        VStack {
                            Spacer()
                            Text("데이터가 충분하지 않아요")
                                .font(.system(size: metrics.font16, weight: .bold))
                                .foregroundStyle(.normalBlack900)
                            Spacer()
                        }
                    )
                } else {
                    ForEach(recentFeedbacks, id: \.id) { feedback in
                        FeedbackSummaryCard(feedback: feedback, scriptTitle: scriptTitle, feedbackNumber: feedbackNumber)
                    }
                    
                    let placeholderCount = 5 - recentFeedbacks.count
                    if placeholderCount > 0 {
                        ForEach(0..<placeholderCount, id: \.self) { _ in
                            FeedbackSummaryCardPlaceholderView()
                        }
                    }
                    
                    Spacer()
                }
            }
            .dashboardCardStyle(
                padding: metrics.cardPadding36,
                style: .border(.primaryBlue200)
            )
        }
    }
}
