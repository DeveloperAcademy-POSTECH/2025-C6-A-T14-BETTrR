//
//  ScriptDashboardBottomLeftContents.swift
//  Bettr
//
//  Created by 길정수 on 11/6/25.
//

import SwiftUI

struct ScriptDashboardBottomLeftContents: View {
    @Environment(NavigationRouter.self) var router
    var feedbacks: [FeedbackSummary]
    
    var body: some View {
        if feedbacks.count > 0 {
            VStack(alignment: .leading, spacing: 20) {
                ForEach(feedbacks, id: \.id) { feedback in
                    Button(action: {
                        router.push(Route.HistoricalFeedback(summary: feedback))
                    }) {
                        FeedbackSummaryCard(feedback: feedback)
                    }
                    .foregroundStyle(Color.primary)
                }
            }
            .frame(maxHeight: .infinity, alignment: .top)
        }
        else {
            VStack {
                Spacer()
                Text("아직 피드백이 없습니다")
                    .font(.system(size: 18))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.primary.opacity(0.05))
            )
        }
    }
}
