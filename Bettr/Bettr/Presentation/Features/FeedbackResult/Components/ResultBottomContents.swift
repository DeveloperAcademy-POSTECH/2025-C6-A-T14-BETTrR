//
//  ResultBottomContents.swift
//  Bettr
//
//  Created by 길정수 on 11/12/25.
//

import SwiftUI

struct ResultBottomContents: View {
    let model: FeedbackResultModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("틀린 문장 모아보기")
                .font(.headingBold28)
                .foregroundStyle(.normalBlack900)
            
            MistakesListView(filteredSentenceDiffs: model.filteredSentenceDiffs)
        }
    }
}

struct MistakesListView: View {
    let filteredSentenceDiffs: [FeedbackResultModel.FilteredSentenceDiff]
    
    var body: some View {
        if filteredSentenceDiffs.isEmpty {
            Text("틀린 문장이 하나도 없습니다.")
                .font(.labelBold16)
                .foregroundColor(.normalBlack900)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .cardBorderedFilled(padding: 36)
        } else {
            HStack(spacing: 36) {
                VStack(spacing: 36) {
                    ForEach(filteredSentenceDiffs, id: \.index) { (originalIndex, sentenceData) in
                        OriginalScriptSentenceView(diffs: sentenceData.diffs)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity)
                
                Divider().foregroundStyle(.primaryBlue200)
                    .frame(maxHeight: .infinity)
                
                VStack(spacing: 36) {
                    ForEach(filteredSentenceDiffs, id: \.index) { (originalIndex, sentenceData) in
                        UserSpeechSentenceView(diffs: sentenceData.diffs)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .cardBordered(padding: 36)
        }
    }
}
