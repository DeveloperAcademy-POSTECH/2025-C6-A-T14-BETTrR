//
//  AllFeedbackView.swift
//  Bettr
//
//  Created by 길정수 on 11/10/25.
//

import SwiftUI

struct AllFeedbackView: View {
    @State var viewModel: AllFeedbackViewModel
    
    private let gridColumns: [GridItem] = [
        GridItem(.flexible(), spacing: 32),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 64) {
                let totalCount = viewModel.allFeedbackCount
                
                // --- 섹션 1: 최근 1시간 동안 생성된 피드백 ---
                if !viewModel.recentFeedbacks.isEmpty {
                    VStack(alignment: .leading, spacing: 24) {
                        Text("최근 1시간 동안 생성된 피드백")
                            .font(.headingBold28)
                            .foregroundStyle(.normalBlack900)
                        
                        LazyVGrid(columns: gridColumns, spacing: 36) {
                            ForEach(viewModel.recentFeedbacks) { feedback in
                                
                                let index = viewModel.allSortedFeedbacks.firstIndex(where: { $0.id == feedback.id }) ?? 0
                                let specificFeedbackNumber = totalCount - index
                                
                                FeedbackSummaryCard(feedback: feedback, scriptTitle: viewModel.scriptTitle, feedbackNumber: specificFeedbackNumber)
                            }
                        }
                        .cardBordered(padding: 36)
                    }
                }
                
                // --- 섹션 2: 이전 모든 피드백 ---
                if !viewModel.previousFeedbacks.isEmpty {
                    VStack(alignment: .leading, spacing: 24) {
                        Text(viewModel.recentFeedbacks.isEmpty ? "모든 피드백" : "이전 모든 피드백")
                            .font(.headingBold28)
                            .foregroundStyle(.normalBlack900)
                        
                        LazyVGrid(columns: gridColumns, spacing: 36) {
                            ForEach(viewModel.previousFeedbacks) { feedback in
                                
                                let index = viewModel.allSortedFeedbacks.firstIndex(where: { $0.id == feedback.id }) ?? 0
                                let specificFeedbackNumber = totalCount - index
                                
                                FeedbackSummaryCard(feedback: feedback, scriptTitle: viewModel.scriptTitle, feedbackNumber: specificFeedbackNumber)
                            }
                        }
                        .cardBordered(padding: 36)
                    }
                }
            }
            .safeAreaPadding(.horizontal, 84)
        }
        .safeAreaPadding(.top, 24)
        .safeAreaPadding(.bottom, 48)
    }
}

// MARK: - Preview

#Preview("1. 모든 데이터가 있을 때") {
    let mockFeedbacks: [FeedbackSummary] = [
        // 1. 최근 (1시간 이내)
        FeedbackSummary(
            id: 1, scriptId: 1, accuracy: 0.95,
            missingWordCount: 1, addedWordCount: 0, replacedWordCount: 1,
            practiceDuration: 120.5, createdAt: Date().addingTimeInterval(-600) // 10분 전
        ),
        FeedbackSummary(
            id: 2, scriptId: 1, accuracy: 0.88,
            missingWordCount: 2, addedWordCount: 1, replacedWordCount: 3,
            practiceDuration: 130.0, createdAt: Date().addingTimeInterval(-1800) // 30분 전
        ),
        
        // 2. 이전 (1시간 이후)
        FeedbackSummary(
            id: 3, scriptId: 1, accuracy: 0.75,
            missingWordCount: 5, addedWordCount: 2, replacedWordCount: 4,
            practiceDuration: 150.2, createdAt: Date().addingTimeInterval(-3700) // 1시간 1분 전
        ),
        FeedbackSummary(
            id: 4, scriptId: 1, accuracy: 0.82,
            missingWordCount: 3, addedWordCount: 3, replacedWordCount: 3,
            practiceDuration: 140.0, createdAt: Date().addingTimeInterval(-7200) // 2시간 전
        ),
        FeedbackSummary(
            id: 5, scriptId: 1, accuracy: 0.90,
            missingWordCount: 1, addedWordCount: 1, replacedWordCount: 2,
            practiceDuration: 135.0, createdAt: Date().addingTimeInterval(-86400) // 1일 전
        )
    ]
    
    let viewModel = AllFeedbackViewModel(
        allFeedbacks: mockFeedbacks,
        scriptTitle: "스티브 잡스 스탠포드 연설",
    )
    
    return NavigationStack {
        AllFeedbackView(viewModel: viewModel)
            .environment(NavigationRouter())
    }
}

#Preview("2. 최근 피드백만 있을 때") {
    let mockFeedbacks: [FeedbackSummary] = [
        FeedbackSummary(
            id: 1, scriptId: 1, accuracy: 0.95,
            missingWordCount: 1, addedWordCount: 0, replacedWordCount: 1,
            practiceDuration: 120.5, createdAt: Date().addingTimeInterval(-600) // 10분 전
        )
    ]
    
    let viewModel = AllFeedbackViewModel(
        allFeedbacks: mockFeedbacks,
        scriptTitle: "최근 스크립트",
    )
    
    return NavigationStack {
        AllFeedbackView(viewModel: viewModel)
            .environment(NavigationRouter())
    }
}

#Preview("3. 이전 피드백만 있을 때") {
    let mockFeedbacks: [FeedbackSummary] = [
        FeedbackSummary(
            id: 3, scriptId: 1, accuracy: 0.75,
            missingWordCount: 5, addedWordCount: 2, replacedWordCount: 4,
            practiceDuration: 150.2, createdAt: Date().addingTimeInterval(-3700) // 1시간 1분 전
        )
    ]
    
    let viewModel = AllFeedbackViewModel(
        allFeedbacks: mockFeedbacks,
        scriptTitle: "오래된 스크립트",
    )
    
    return NavigationStack {
        AllFeedbackView(viewModel: viewModel)
            .environment(NavigationRouter())
    }
}
