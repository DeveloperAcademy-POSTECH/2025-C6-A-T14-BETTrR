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
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(sentences, id: \.orderIndex) { sentence in
                        Text(sentence.englishText)
                            .font(.system(size: 20))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: .infinity, alignment: .top)
            
            Button(action: {
                router.push(Route.memorization(scriptId: scriptId))
            }) {
                Text("암기하기")
                    .foregroundStyle(.white)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 50)
                    .background(
                        RoundedRectangle(cornerRadius: 100)
                            .fill(Color.blue)
                    )
                    .glassEffect()
            }
        }
        .padding(.vertical, 25)
        .padding(.horizontal, 40)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.primary.opacity(0.05))
                .strokeBorder(Color.primary.opacity(0.5), lineWidth: 1)
        )
    }
}
