//
//  FeedbackSummaryCard.swift
//  Bettr
//
//  Created by 길정수 on 11/6/25.
//

import SwiftUI

struct FeedbackSummaryCard: View {
    @Environment(NavigationRouter.self) var router
    @Environment(\.metrics) var metrics
    
    let feedback: FeedbackSummary
    
    var body: some View {
        Button(action: {
            router.push(Route.historicalFeedback(summary: feedback))
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 12) {
                    Text("\(Int(feedback.accuracy * 100))%")
                        .font(.subtitleSemibold24)
                    
                    HStack(spacing: metrics.cardSpacing) {
                        Text("누락된 단어 \(feedback.missingWordCount)")
                        Text("|")
                        Text("추가된 단어 \(feedback.addedWordCount)")
                        Text("|")
                        Text("대체된 단어 \(feedback.replacedWordCount)")
                    }
                    .font(.system(size: metrics.font14, weight: .regular))
                }
                
                Spacer()
                
                HStack(spacing: metrics.buttonSpacing) {
                    Text(feedback.createdAt.asAppDateString())
                    Image(systemName: "chevron.right")
                }
                .font(.system(size: metrics.font16, weight: .regular))
            }
            .foregroundStyle(.normalBlack900)
        }
    }
}

struct FeedbackSummaryCardPlaceholderView: View {
    @Environment(\.metrics) var metrics

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: metrics.cardSpacing) {
                Text(" ")
                    .font(.system(size: metrics.font24, weight: .semibold))

                HStack(spacing: metrics.cardSpacing) {
                    Text(" ")
                    Text(" ")
                    Text(" ")
                    Text(" ")
                    Text(" ")
                }
                .font(.system(size: metrics.font14, weight: .regular))
            }
            
            Spacer()
            
            HStack(spacing: metrics.buttonSpacing) {
                Text(" ")
                Image(systemName: "chevron.right")
            }
            .font(.system(size: metrics.font16, weight: .regular))
        }
        .opacity(0)
    }
}
