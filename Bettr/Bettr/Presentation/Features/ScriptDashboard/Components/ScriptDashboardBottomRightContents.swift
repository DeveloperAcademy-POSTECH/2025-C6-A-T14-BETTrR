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
        Text(combinedSentences)
            .font(.calloutRegular20)
            .foregroundStyle(.normalBlack900)
            .lineLimit(nil)
            .truncationMode(.tail)
            .padding(.vertical, 25)
            .padding(.horizontal, 36)
            .frame(maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.primaryBlue50)
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
