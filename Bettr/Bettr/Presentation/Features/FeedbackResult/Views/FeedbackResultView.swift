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
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task {
                await viewModel.saveFeedbackResult()
            }
        }
    }
}
