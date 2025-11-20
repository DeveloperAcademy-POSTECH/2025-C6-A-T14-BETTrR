//
//  FeedbackSummaryCard.swift
//  Bettr
//
//  Created by 길정수 on 11/6/25.
//

import SwiftUI

struct FeedbackSummaryCard: View {
    @Environment(NavigationRouter.self) var modalRouter
    let feedback: FeedbackSummary
    let scriptTitle: String
    let feedbackNumber: Int
    
    var body: some View {
        Button(action: {
            modalRouter.push(ModalRoute.feedbackResult(summaryId: feedback.id!, fromRecording: false))
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 12) {
                    Text("\(Int(feedback.accuracy * 100))%")
                        .font(.subtitleSemibold24)
                    
                    HStack(spacing: 6) {
                        Text("누락된 단어 \(feedback.missingWordCount)")
                        Text("|")
                        Text("추가된 단어 \(feedback.addedWordCount)")
                        Text("|")
                        Text("대체된 단어 \(feedback.replacedWordCount)")
                    }
                    .font(.labelRegular14)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.calloutRegular16)
            }
            .foregroundStyle(.normalBlack900)
        }
    }
}

struct FeedbackSummaryCardPlaceholderView: View {

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 12) {
                Text(" ")
                    .font(.subtitleSemibold24)
                
                HStack(spacing: 6) {
                    Text(" ")
                    Text(" ")
                    Text(" ")
                    Text(" ")
                    Text(" ")
                }
                .font(.labelRegular14)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
            .font(.calloutRegular16)
        }
        .opacity(0)
    }
}
