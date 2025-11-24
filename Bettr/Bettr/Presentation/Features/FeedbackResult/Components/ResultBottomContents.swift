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
            
            MistakesListCard(filteredSentenceDiffs: model.filteredSentenceDiffs)
                .frame(maxHeight: .infinity, alignment: .top)
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }
}

struct MistakesListCard: View {
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

// MARK: - Preview

#Preview("틀린 문장 있음") {
    let model = FeedbackResultModel(
        scriptTitle: "Preview Script Title",
        feedbackNumber: 5,
        accuracy: 0.75,
        totalRecordingTime: 120.5,
        missingCount: 2,
        extraCount: 1,
        replacedCount: 1,
        filteredSentenceDiffs: [
            (index: 0, data: (original: "Hello world, how are you?", diffs: [
                .matched(word: "Hello"), .matched(word: "world"), .missing(expected: "how"),
                .extra(actual: "are"), .replaced(expected: "you", actual: "yoo")
            ])),
            (index: 1, data: (original: "I am fine, thank you.", diffs: [
                .matched(word: "I"), .matched(word: "am"), .matched(word: "fine"),
                .extra(actual: "very"), .matched(word: "thank"), .missing(expected: "you")
            ]))
        ]
    )
    
    return ResultBottomContents(model: model)
}

#Preview("틀린 문장 없음 (완벽)") {
    let perfectModel = FeedbackResultModel(
        scriptTitle: "Perfect Script",
        feedbackNumber: 1,
        accuracy: 1.0,
        totalRecordingTime: 60.0,
        missingCount: 0,
        extraCount: 0,
        replacedCount: 0,
        filteredSentenceDiffs: []
    )
    
    return ResultBottomContents(model: perfectModel)
}
