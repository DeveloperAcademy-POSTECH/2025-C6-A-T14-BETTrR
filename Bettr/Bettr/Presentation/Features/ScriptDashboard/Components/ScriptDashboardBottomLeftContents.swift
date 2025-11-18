//
//  ScriptDashboardBottomLeftContents.swift
//  Bettr
//
//  Created by 길정수 on 11/6/25.
//

import SwiftUI

struct ScriptDashboardBottomLeftContents: View {
    @Environment(NavigationRouter.self) var router
    
    let viewModel: ScriptDashboardViewModel
    
    private var recentFeedbacks: [FeedbackSummary] {
        viewModel.scriptDashboardData?.recentFeedbacks ?? []
    }
    private var allFeedbacks: [FeedbackSummary] {
        viewModel.scriptDashboardData?.allFeedbacks ?? []
    }
    private var scriptTitle: String {
        viewModel.currentTitle
    }
    private var feedbackNumber: Int {
        viewModel.scriptDashboardData?.stats.feedbackCount ?? 0
    }
    
    var body: some View {
        
        VStack(spacing: 8) {
            
            // 타이틀과 더보기 버튼
            HStack {
                Text("최근 생성된 피드백")
                    .font(.subbodyBold24)
                    .padding(8)
                
                Spacer()
                
                if allFeedbacks.count > 5 {
                    Button(action: {
                        router.push(Route.allFeedback(feedbacks: allFeedbacks, scriptTitle: scriptTitle, feedbackNumber: feedbackNumber))
                    }) {
                        HStack(spacing: 4) {
                            Text("더보기")
                            Image(systemName: "chevron.right")
                        }
                        .font(.labelRegular14)
                    }
                }
            }
            .foregroundStyle(.normalBlack900)
            
            
            if recentFeedbacks.isEmpty {
                VStack(spacing: 16) {
                    ForEach(0..<5, id: \.self) { _ in
                        FeedbackSummaryCardPlaceholderView()
                        Spacer(minLength: 0)
                    }
                }
                .cardBordered(padding: 36)
                .overlay(
                    VStack(alignment: .center) {
                        Text("데이터가 충분하지 않아요")
                            .font(.labelBold16)
                            .foregroundStyle(.normalBlack900)
                    }
                )
            } else {
                VStack(spacing: 16) {
                    ForEach(recentFeedbacks, id: \.id) { feedback in
                        FeedbackSummaryCard(feedback: feedback, scriptTitle: scriptTitle, feedbackNumber: feedbackNumber)
                        Spacer(minLength: 0)
                    }
                    
                    let placeholderCount = 5 - recentFeedbacks.count
                    if placeholderCount > 0 {
                        ForEach(0..<placeholderCount, id: \.self) { _ in
                            FeedbackSummaryCardPlaceholderView()
                            Spacer(minLength: 0)
                        }
                    }
                }
                .cardBordered(padding: 36)
            }
        }
    }
}
