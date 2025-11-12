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
            
            // 로딩 성공 시, 옵셔널 바인딩으로 resultModel을 가져옵니다.
            } else if let resultModel = viewModel.resultModel {
                // DisplayView에 모델 하나만 전달합니다.
                FeedbackResultDisplayView(model: resultModel)
                
            } else {
                // (방어 코드) 로딩이 false고, 에러도 없는데 모델이 nil인 경우
                Text("데이터를 불러오지 못했습니다.")
            }
        }
        .navigationTitle("분석 결과")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if viewModel.resultModel == nil {
                await viewModel.loadFeedbackData()
            }
        }
    }
}
