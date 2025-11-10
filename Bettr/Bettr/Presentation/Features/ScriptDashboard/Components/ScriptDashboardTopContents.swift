//
//  ScriptDashboardTopContents.swift
//  Bettr
//
//  Created by 길정수 on 11/6/25.
//

import SwiftUI

struct ScriptDashboardTopContents: View {
    var viewModel: ScriptDashboardViewModel
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            if let data = viewModel.scriptDashboardData {
                ScriptDashboardTopLeftContents(feedbacks: data.recentFeedbacks)
                
                ScriptDashboardTopRightContents(
                    feedbackCount: data.feedbackCount,
                    top3IncorrectWords: data.top3IncorrectWords,
                    averagePracticeDuration: data.averagePracticeDuration,
                    recentFeedbackCount: data.recentFeedbackCount
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
