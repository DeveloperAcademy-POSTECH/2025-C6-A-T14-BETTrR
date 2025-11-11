//
//  HistoricalFeedbackView.swift
//  Bettr
//
//  Created by 길정수 on 11/5/25.
//

import SwiftUI

struct HistoricalFeedbackView: View {
    @State private var viewModel: HistoricalFeedbackViewModel
    
    init(viewModel: HistoricalFeedbackViewModel) {
        _viewModel = State(initialValue: viewModel)
    }
    
    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView("결과를 불러오는 중...")
            } else if let error = viewModel.loadError {
                VStack {
                    Text("오류")
                        .font(.largeTitle)
                    Text("결과를 불러오는 데 실패했습니다: \(error.localizedDescription)")
                        .foregroundColor(.secondary)
                        .padding()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                FeedbackResultDisplayView(
                    scriptTitle: viewModel.scriptTitle,
                    feedbackNumber: viewModel.feedbackNumber,
                    accuracy: viewModel.accuracy,
                    totalRecordingTime: viewModel.totalRecordingTime,
                    missingCount: viewModel.missingCount,
                    extraCount: viewModel.extraCount,
                    replacedCount: viewModel.replacedCount,
                    filteredSentenceDiffs: viewModel.filteredSentenceDiffs,
                    hasSentences: viewModel.hasSentences
                )
            }
        }
        .navigationTitle("분석 결과")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if viewModel.filteredSentenceDiffs.isEmpty && viewModel.hasSentences == false {
                await viewModel.loadFeedbackData()
            }
        }
    }
}
