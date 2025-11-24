//
//  SpeechComparisonCard.swift
//  Bettr
//
//  Created by 길정수 on 11/24/25.
//

import SwiftUI

struct SpeechComparisonCard: View {
    let filteredSentenceDiffs: [FeedbackResultModel.FilteredSentenceDiff]
    
    var body: some View {
        HStack(alignment: .top, spacing: 72) {
            VStack(spacing: 36) {
                ForEach(filteredSentenceDiffs, id: \.index) { (originalIndex, sentenceData) in
                    OriginalScriptSentenceView(diffs: sentenceData.diffs)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity)
            
            VStack(spacing: 36) {
                ForEach(filteredSentenceDiffs, id: \.index) { (originalIndex, sentenceData) in
                    UserSpeechSentenceView(diffs: sentenceData.diffs)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .cardBordered(padding: 36)
        .overlay {
            Rectangle()
                .foregroundStyle(.primaryBlue200)
                .frame(width: 1)
                .padding(.vertical, 36)
        }
    }
}
