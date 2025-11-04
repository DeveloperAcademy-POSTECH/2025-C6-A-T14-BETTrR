//
//  FeedbackResultView.swift
//  Bettr
//
//  Created by 길정수 on 10/30/25.
//

import Foundation
import SwiftUI

struct FeedbackResultView: View {
    
    @State private var viewModel: FeedbackViewModel
    
    init(viewModel: FeedbackViewModel) {
        _viewModel = State(initialValue: viewModel)
    }
    
    var body: some View {
        VStack {
            if let feedback = viewModel.feedbackResult {
                FeedbackResultDisplayView(
                    accuracy: feedback.accuracy,
                    totalRecordingTime: feedback.totalRecordingTime,
                    missingCount: viewModel.missingCount,
                    extraCount: viewModel.extraCount,
                    replacedCount: viewModel.replacedCount,
                    filteredSentenceDiffs: viewModel.filteredSentenceDiffs,
                    hasSentences: !viewModel.sentenceDiffs.isEmpty
                )
            } else {
                // viewModel.feedbackResult가 nil일 경우(ex. 분석 실패)를 대비
                VStack {
                    Text("오류")
                        .font(.largeTitle)
                    Text("피드백 결과를 불러오는 데 실패했습니다.")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationBarBackButtonHidden()
        .cancelToolbar()
        .navigationTitle("분석 결과")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task {
                await viewModel.saveFeedbackResult()
            }
        }
    }
}
