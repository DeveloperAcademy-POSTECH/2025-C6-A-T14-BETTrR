//
//  ScriptDashboardBottomContents.swift
//  Bettr
//
//  Created by 길정수 on 11/6/25.
//

import SwiftUI

struct ScriptDashboardBottomContents: View {
    var viewModel: ScriptDashboardViewModel
    
    var body: some View {
        HStack(spacing: 16) {
            GeometryReader { geometry in
                HStack(spacing: 16) {
                    if let data = viewModel.scriptDashboardData {
                        ScriptDashboardBottomLeftContents(recentFeedbacks: data.recentFeedbacks, allFeedbacks: data.allFeedbacks)
                            .frame(width: geometry.size.width * 0.5 - 8, alignment: .leading)
                        
                        ScriptDashboardBottomRightContents(scriptId: viewModel.scriptId, sentences: data.sentences)
                            .frame(width: geometry.size.width * 0.5 - 8, alignment: .leading)
                    }
                }
            }
        }
    }
}
