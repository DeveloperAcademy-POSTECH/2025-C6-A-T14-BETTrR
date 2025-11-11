//
//  FeedbackSummaryCard.swift
//  Bettr
//
//  Created by 길정수 on 11/6/25.
//

import SwiftUI

struct FeedbackSummaryCard: View {
    @Environment(NavigationRouter.self) var router
    let feedback: FeedbackSummary
    
    var body: some View {
        Button(action: {
            router.push(Route.historicalFeedback(summary: feedback))
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 12) {
                    Text("\(Int(feedback.accuracy * 100))%")
                        .font(.subtitleSemibold24)
                    
                    HStack(spacing: 12) {
                        Text("누락된 단어 \(feedback.missingWordCount)")
                        Text("|")
                        Text("추가된 단어 \(feedback.addedWordCount)")
                        Text("|")
                        Text("대체된 단어 \(feedback.replacedWordCount)")
                    }
                    .font(.labelRegular14)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    Text(feedback.createdAt.asAppDateString())
                    Image(systemName: "chevron.right")
                }
                .font(.calloutRegular16)
            }
            .foregroundStyle(.normalBlack900)
        }
    }
}
