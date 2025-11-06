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
        HStack(spacing: 16) {
            
            if let data = viewModel.scriptDashboardData, data.feedbackCount > 0 {
                GeometryReader { geometry in
                    HStack(spacing: 16) {
                        ScriptDashboardTopLeftContents()
                            .frame(width: geometry.size.width * 0.5, alignment: .leading)
                        
                        ScriptDashboardTopRightContents(
                            feedbackCount: data.feedbackCount,
                            top3IncorrectWords: data.top3IncorrectWords,
                            averagePracticeDuration: data.averagePracticeDuration,
                            recentFeedbackCount: data.recentFeedbackCount
                        )
                        .frame(width: geometry.size.width * 0.5, alignment: .leading)
                    }
                }
            }
        }
    }
}
