//
//  FullFeedbackHistoryStatistics.swift
//  Bettr
//
//  Created by 길정수 on 11/20/25.
//


import SwiftUI
import Charts

struct FullFeedbackHistoryStatistics: View {
    
    @Environment(NavigationRouter.self) private var modalRouter
    
    let viewModel: FeedbackHistoryViewModel
    
    private var allFeedbackSummaries: [FeedbackSummary] {
        viewModel.feedbackHistoryData?.allFeedbackSummaries ?? []
    }
    
    private var frequentlyWrongWords: [WrongWordCount] {
        viewModel.feedbackHistoryData?.frequentlyWrongWords ?? []
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            VStack(alignment: .leading, spacing: 48) {
                ScoreTrendSection(summaries: allFeedbackSummaries)
                
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
            }
            
            Spacer(minLength: 24)
            
            StartTestButton(viewModel: viewModel)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .cardBordered(padding: 36)
    }
}

struct CompactFeedbackStatistics: View {
    @Environment(NavigationRouter.self) private var modalRouter
    
    let viewModel: FeedbackHistoryViewModel
    
    private var allFeedbackSummaries: [FeedbackSummary] {
        viewModel.feedbackHistoryData?.allFeedbackSummaries ?? []
    }
    
    private var frequentlyWrongWords: [WrongWordCount] {
        viewModel.feedbackHistoryData?.frequentlyWrongWords ?? []
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 24) {
            ScoreTrendSection(summaries: allFeedbackSummaries)
            
            FrequentlyWrongWordsSection(
                wrongWords: frequentlyWrongWords,
                maxDisplayCount: 3
            )
                            
            StartTestButton(viewModel: viewModel)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .cardBordered(padding: 36)
    }
}

