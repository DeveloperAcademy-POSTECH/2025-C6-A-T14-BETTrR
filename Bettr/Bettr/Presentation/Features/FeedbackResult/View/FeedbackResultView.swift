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
            FeedbackResultDisplayView(model: viewModel.resultModel)
        }
        .navigationBarBackButtonHidden()
        .cancelToolbar()
        .navigationTitle("분석 결과")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task {
                await viewModel.saveFeedbackResult(practiceDuration: viewModel.practiceDuration)
            }
        }
    }
}
