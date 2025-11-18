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
            if viewModel.isLoading { // 로딩
                ProgressView()
            } else if let error = viewModel.loadError { // 에러
                ErrorView(error: error) {
                    Task { // 재시도 로직
                        await viewModel.loadFeedbackData()
                    }
                }
            } else if let resultModel = viewModel.resultModel { // 성공
                FeedbackResultDisplayView(model: resultModel)
            } else {
                // 예외 케이스: 로딩도 아니고, 에러도 아닌데, 데이터도 없는 경우
                ErrorView(error: .unknown("데이터를 불러오지 못했습니다.")) {
                    Task {
                        await viewModel.loadFeedbackData()
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if viewModel.resultModel == nil {
                await viewModel.loadFeedbackData()
            }
        }
    }
}
