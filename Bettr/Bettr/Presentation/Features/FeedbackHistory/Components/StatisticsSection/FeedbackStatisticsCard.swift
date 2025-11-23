//
//  FeedbackStatisticsCard.swift
//  Bettr
//
//  Created by 길정수 on 11/20/25.
//


import SwiftUI

struct FeedbackStatisticsCard: View {
    let viewModel: FeedbackHistoryViewModel
    let layoutMode: FeedbackStatisticsLayoutMode
    
    private var allFeedbackSummaries: [FeedbackSummary] {
        viewModel.feedbackHistoryData?.allFeedbackSummaries ?? []
    }
    
    private var frequentlyWrongWords: [WrongWordCount] {
        viewModel.feedbackHistoryData?.frequentlyWrongWords ?? []
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            
            VStack(alignment: .leading, spacing: layoutMode.spacing) {
                // 그래프
                ScoreTrendSection(summaries: allFeedbackSummaries)
                
                // 자주 틀린 단어
                if layoutMode == .full {
                    ViewThatFits(in: .vertical) {
                        FrequentlyWrongWordsSection(
                            wrongWords: frequentlyWrongWords,
                            maxDisplayCount: 5
                        )
                        
                        FrequentlyWrongWordList(
                            frequentlyWrongWords: frequentlyWrongWords,
                            maxDisplayCount: 3
                        )
                    }
                } else {
                    FrequentlyWrongWordsSection(
                        wrongWords: frequentlyWrongWords,
                        maxDisplayCount: 3
                    )
                }
            }
            
            // 버튼
            if layoutMode == .full {
                Spacer(minLength: 24)
                StartTestButton(viewModel: viewModel)
            } else {
                StartTestButton(viewModel: viewModel)
                    .padding(.top, 24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .cardBordered(padding: 36)
    }
}
