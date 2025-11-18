//
//  ScriptDashboardBottomRightContents.swift
//  Bettr
//
//  Created by 길정수 on 11/6/25.
//

import SwiftUI

struct ScriptDashboardBottomRightContents: View {
    @Environment(NavigationRouter.self) var router
    
    let viewModel: ScriptDashboardViewModel
    
    private var scriptId: Int64 {
        viewModel.scriptId
    }
    private var sentences: [ScriptDashboardSentenceModel] {
        viewModel.scriptDashboardData?.sentences ?? []
    }
    private var scriptTitle: String {
        viewModel.currentTitle
    }
    private var currentFeedbackCount: Int {
        viewModel.scriptDashboardData?.stats.feedbackCount ?? 0
    }
    
    private var combinedSentences: String {
        sentences.map { $0.englishText }.joined(separator: "\n\n")
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(combinedSentences)
                .font(.calloutRegular20)
                .foregroundStyle(.normalBlack900)
                .lineLimit(nil)
                .truncationMode(.tail)
            
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: 546)
        .cardFilled(padding: 36)
        .overlay(alignment: .center) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.red.opacity(0.7))
                
                Button(action: {
                    router.push(Route.memorization(scriptId: scriptId, scriptTitle: scriptTitle, currentFeedbackCount: currentFeedbackCount))
                }) {
                    Text("암기하기")
                        .font(.labelBold16)
                }
                .buttonStyle(.general)
            }
        }
    }
}
