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
                        router.push(Route.allFeedback(feedbacks: allFeedbacks, scriptTitle: scriptTitle))
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
                .frame(maxWidth: .infinity, maxHeight: 546)
                .cardBordered(padding: 36)
                .overlay {
                    Text("최근 생성된 피드백이 없습니다")
                        .font(.calloutRegular16)
                        .foregroundStyle(.normalGray600)
                }
            } else {
                VStack(spacing: 16) {
                    
                    let totalFeedbackCount = allFeedbacks.count
                    
                    ForEach(Array(recentFeedbacks.enumerated()), id: \.element.id) { (index, feedback) in
                        
                        let specificFeedbackNumber = totalFeedbackCount - index
                        
                        FeedbackSummaryCard(feedback: feedback, scriptTitle: scriptTitle, feedbackNumber: specificFeedbackNumber)
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
                .frame(maxWidth: .infinity, maxHeight: 546)
                .cardBordered(padding: 36)
            }
        }
    }
}

// MARK: - Preview

