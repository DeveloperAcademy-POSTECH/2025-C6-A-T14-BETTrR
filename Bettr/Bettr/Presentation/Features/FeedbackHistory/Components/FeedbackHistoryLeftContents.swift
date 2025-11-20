//
//  FeedbackHistoryLeftContents.swift
//  Bettr
//
//  Created by 길정수 on 11/20/25.
//


import SwiftUI
import Charts

struct FeedbackHistoryLeftContents: View {
    let viewModel: FeedbackHistoryViewModel
    
    private var allFeedbackSummaries: [FeedbackSummary] {
        viewModel.feedbackHistoryData?.allFeedbackSummaries ?? []
    }
    
    private var frequentlyWrongWords: [WrongWordCount] {
        viewModel.feedbackHistoryData?.frequentlyWrongWords ?? []
    }
    
    var body: some View {
        VStack(spacing: 60) {
            AccuracyGraphSection(allFeedbackSummaries: allFeedbackSummaries)
            FrequentlyWrongWordsSection(frequentlyWrongWords: frequentlyWrongWords)
        }
    }
}