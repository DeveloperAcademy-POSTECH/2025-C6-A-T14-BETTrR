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
    
    var body: some View {
        
        VStack(spacing: 8) {
            HStack {
                Text("최근 생성된 피드백")
                    .font(.subbodyBold24)
                
                Spacer()
                
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
            .padding(8)
            .foregroundStyle(.normalBlack900)
            
            if recentFeedbacks.count > 0 {
                VStack(spacing: 20) {
                    ForEach(recentFeedbacks, id: \.id) { feedback in
                        FeedbackSummaryCard(feedback: feedback)
                    }
                    Spacer()
                }
                .dashboardCardStyle(padding: 36)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            else {
                VStack {
                    Spacer()
                    Text("데이터가 충분하지 않아요")
                        .font(.labelBold16)
                        .foregroundStyle(.normalBlack900)
                    
                    Spacer()
                }
                .dashboardCardStyle(padding: 36)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}
