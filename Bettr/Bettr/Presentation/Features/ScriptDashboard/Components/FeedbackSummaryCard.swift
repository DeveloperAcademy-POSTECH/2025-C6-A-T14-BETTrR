//
//  FeedbackSummaryCard.swift
//  Bettr
//
//  Created by 길정수 on 11/6/25.
//

import SwiftUI

struct FeedbackSummaryCard: View {
    let feedback: FeedbackSummary
    
    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle().fill(Color.gray.opacity(0.5))
                Text("\(Int(feedback.accuracy * 100))%")
            }
            .frame(width: 60, height: 60)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(feedback.practiceDuration.asPracticeDurationString())
                Text("누락된 단어 \(feedback.missingWordCount) | 추가된 단어 \(feedback.addedWordCount) | 대체된 단어 \(feedback.replacedWordCount)")
            }
            
            Spacer()
            
            Text(feedback.createdAt.asAppDateString())
        }
    }
}
