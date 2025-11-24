//
//  IncorrectSentenceSection.swift
//  Bettr
//
//  Created by 길정수 on 11/12/25.
//

import SwiftUI

struct IncorrectSentenceSection: View {
    let model: FeedbackResultModel
    
    var body: some View {
        TitledSection.large(title: "틀린 문장 모아보기") {
            if model.filteredSentenceDiffs.isEmpty {
                // 틀린 문장 없음
                VStack {
                    Spacer()
                    Text("틀린 문장이 하나도 없습니다.")
                        .font(.labelBold16)
                        .foregroundStyle(.normalBlack900)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .cardBorderedFilled(padding: 36)
                
            } else {
                // 틀린 문장 있음
                SpeechComparisonCard(filteredSentenceDiffs: model.filteredSentenceDiffs)
                    .frame(maxHeight: .infinity, alignment: .top)
            }
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
    
    return IncorrectSentenceSection(model: model)
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
    
    return IncorrectSentenceSection(model: perfectModel)
}
