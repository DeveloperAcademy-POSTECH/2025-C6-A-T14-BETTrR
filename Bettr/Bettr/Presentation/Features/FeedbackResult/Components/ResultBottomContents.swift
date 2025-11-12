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
            VStack(spacing: 0) {
                ForEach(filteredSentenceDiffs, id: \.index) { (originalIndex, sentenceData) in
                    MistakeRowView(sentenceData: sentenceData)
                }
            }
            .cardBordered(padding: 0)
        }
    }
}

private struct MistakeRowView: View {
    let sentenceData: FeedbackResultModel.SentenceDiffData
    
    var body: some View {
        HStack(spacing: 0) {
            // 왼쪽: 발화 분석 결과
            HighlightedTextView(diffs: sentenceData.diffs)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(36)
            
            Spacer()
            Divider().foregroundStyle(.primaryBlue200)
            Spacer()
            
            // 오른쪽: 원본 문장
            Text(sentenceData.original)
                .font(.subbodyRegular20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(36)
        }
    }
}
