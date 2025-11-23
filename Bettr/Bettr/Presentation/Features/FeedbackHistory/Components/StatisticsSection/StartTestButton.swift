//
//  StartTestButton.swift
//  Bettr
//
//  Created by 길정수 on 11/23/25.
//

import SwiftUI

struct StartTestButton: View {
    
    let viewModel: FeedbackHistoryViewModel
    @Environment(NavigationRouter.self) private var modalRouter
    
    private var isTestReady: Bool {
        guard let data = viewModel.feedbackHistoryData,
              let sentences = data.scriptSentences,
              !sentences.isEmpty else {
            return false
        }
        return true
    }
    
    var body: some View {
        Button(action: {
            guard let data = viewModel.feedbackHistoryData,
                  let sentences = data.scriptSentences else { return }
            
            modalRouter.push(ModalRoute.recording(
                scriptId: viewModel.scriptId,
                scriptTitle: viewModel.currentTitle,
                sentences: sentences
            ))
        }) {
            Text("테스트 하러 가기")
                .font(.labelBold16)
        }
        .buttonStyle(.general)
        .disabled(!isTestReady)
    }
}
