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
        ZStack {
            VStack {
                FeedbackResultDisplayView(model: viewModel.resultModel)
            }
            .navigationBarBackButtonHidden()
            .cancelToolbar()
            .navigationBarTitleDisplayMode(.inline)
            
            // 로딩
            if viewModel.isSaving {
                ProgressView()
            }
            
            // 에러
            if let error = viewModel.saveError {
                ErrorView(error: error) {
                    Task {
                        await viewModel.saveFeedbackResult()
                    }
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.saveFeedbackResult()
            }
        }
    }
}
