//
//  FeedbackResultDisplayView.swift
//  Bettr
//
//  Created by 길정수 on 11/4/25.
//

import Foundation
import SwiftUI

struct FeedbackResultDisplayView: View {
    let model: FeedbackResultModel
    
    var body: some View {
        Group {
            if model.filteredSentenceDiffs.isEmpty {
                VStack(alignment: .leading, spacing: 64) {
                    FeedbackSummarySection(model: model)
                    IncorrectSentenceSection(model: model)
                        .frame(maxHeight: .infinity, alignment: .top)
                }
                .frame(maxWidth: .infinity)
                .safeAreaPadding(.horizontal, 84)
            } else {
                GeometryReader { geometry in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 64) {
                            FeedbackSummarySection(model: model)
                            IncorrectSentenceSection(model: model)
                            .frame(maxHeight: .infinity, alignment: .top)                        }
                        .frame(maxWidth: .infinity)
                        .safeAreaPadding(.horizontal, 84)
                        .frame(minHeight: geometry.size.height)
                    }
                }
            }
        }
        .safeAreaPadding(.top, 24)
        .safeAreaPadding(.bottom, 48)
    }
}

// MARK: - Preview

#Preview("일반 피드백") {
    let model = FeedbackResultModel(
        scriptTitle: "Preview Script Title",
        feedbackNumber: 5,
        accuracy: 0.75,
        totalRecordingTime: 120.5,
        missingCount: 12,
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
    return FeedbackResultDisplayView(model: model)
}

#Preview("완벽한 발음") {
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
    return FeedbackResultDisplayView(model: perfectModel)
}
