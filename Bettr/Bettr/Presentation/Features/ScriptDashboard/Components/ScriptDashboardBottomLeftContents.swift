//
//  ScriptDashboardBottomLeftContents.swift
//  Bettr
//
//  Created by 길정수 on 11/6/25.
//

import SwiftUI

struct ScriptDashboardBottomLeftContents: View {
    @Environment(NavigationRouter.self) var router
    
    var recentFeedbacks: [FeedbackSummary]
    var allFeedbacks: [FeedbackSummary]
    
    @ScaledMetric(relativeTo: .title2) var listSpacing: CGFloat = 20
    
    var body: some View {
        
        VStack(spacing: 8) {
            HStack {
                Text("최근 생성된 피드백")
                    .font(.subbodyBold24)
                
                Spacer()
                
                if allFeedbacks.count > 5 {
                    Button(action: {
                        router.push(Route.allFeedback(feedbacks: allFeedbacks))
                    }) {
                        HStack(spacing: 4) {
                            Text("더보기")
                            Image(systemName: "chevron.right")
                        }
                        .font(.labelRegular14)
                    }
                }
            }
            .padding(8)
            .foregroundStyle(.normalBlack900)
            
            VStack(spacing: listSpacing) {
                if recentFeedbacks.isEmpty {
                    VStack(spacing: 20) {
                        ForEach(0..<5, id: \.self) { _ in
                            FeedbackSummaryCardPlaceholderView()
                        }
                        Spacer()
                    }
                    .overlay(
                        VStack {
                            Spacer()
                            Text("데이터가 충분하지 않아요")
                                .font(.labelBold16)
                                .foregroundStyle(.normalBlack900)
                            Spacer()
                        }
                    )
                } else {
                    ForEach(recentFeedbacks, id: \.id) { feedback in
                        FeedbackSummaryCard(feedback: feedback)
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
                padding: 36,
                relativeTo: .title2,
                style: .border(.primaryBlue200)
            )
        }
    }
}
