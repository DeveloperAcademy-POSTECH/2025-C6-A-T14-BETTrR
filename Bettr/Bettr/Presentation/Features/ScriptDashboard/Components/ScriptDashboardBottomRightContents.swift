//
//  ScriptDashboardBottomRightContents.swift
//  Bettr
//
//  Created by 길정수 on 11/6/25.
//

import SwiftUI

struct ScriptDashboardBottomRightContents: View {
    @Environment(NavigationRouter.self) var router
    var scriptId: Int64
    var sentences: [ScriptDashboardSentenceModel]
    
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
        .dashboardCardStyle(
            top: 25, leading: 36, bottom: 25, trailing: 36,
            relativeTo: .title3,
            style: .fill(.primaryBlue50)
        )
        .overlay(alignment:. center) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.defaultWhite50.opacity(0.3))
                
                Button(action: {
                    router.push(Route.memorization(scriptId: scriptId))
                }) {
                    Text("암기하기")
                }
                .buttonStyle(.general)
            }
        }
    }
}
