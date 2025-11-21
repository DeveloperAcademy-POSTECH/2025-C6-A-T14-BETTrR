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
                AccuracyGraphSection(allFeedbackSummaries: allFeedbackSummaries)
                
                ViewThatFits(in: .vertical) {
                    FrequentlyWrongWordsSection(
                        frequentlyWrongWords: frequentlyWrongWords,
                        maxDisplayCount: 5
                    )
                    
                    FrequentlyWrongWordsSection(
                        frequentlyWrongWords: frequentlyWrongWords,
                        maxDisplayCount: 3
                    )
                }
            }
            
            Spacer(minLength: 24)
            
            Button(action: {
                guard let data = viewModel.feedbackHistoryData,
                      let sentences = data.scriptSentences else {
                    print("스크립트 문장 데이터가 없습니다.")
                    return
                }
                modalRouter.push(ModalRoute.recording(
                    scriptId: viewModel.scriptId,
                    scriptTitle: viewModel.currentTitle,
                    sentences: sentences,
                ))
            }) {
                Text("테스트 하러 가기")
                    .font(.labelBold16)
            }
            .buttonStyle(.general)
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
            AccuracyGraphSection(allFeedbackSummaries: allFeedbackSummaries)
            
            FrequentlyWrongWordsSection(
                frequentlyWrongWords: frequentlyWrongWords,
                maxDisplayCount: 3
            )
                            
            Button(action: {
                guard let data = viewModel.feedbackHistoryData,
                      let sentences = data.scriptSentences else {
                    print("스크립트 문장 데이터가 없습니다.")
                    return
                }
                modalRouter.push(ModalRoute.recording(
                    scriptId: viewModel.scriptId,
                    scriptTitle: viewModel.currentTitle,
                    sentences: sentences,
                ))
            }) {
                Text("테스트 하러 가기")
                    .font(.labelBold16)
            }
            .buttonStyle(.general)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .cardBordered(padding: 36)
    }
}

