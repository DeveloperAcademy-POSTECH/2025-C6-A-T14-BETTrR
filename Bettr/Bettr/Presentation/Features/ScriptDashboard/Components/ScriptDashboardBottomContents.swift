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
        HStack(alignment: .top, spacing: 16) {
            if let data = viewModel.scriptDashboardData {
                ScriptDashboardBottomLeftContents(recentFeedbacks: data.recentFeedbacks, allFeedbacks: data.allFeedbacks)
                
                ScriptDashboardBottomRightContents(scriptId: viewModel.scriptId, sentences: data.sentences)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
