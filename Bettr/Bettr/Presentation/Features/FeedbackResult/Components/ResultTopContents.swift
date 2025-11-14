//
//  ResultTopContents.swift
//  Bettr
//
//  Created by 길정수 on 11/12/25.
//

import SwiftUI

struct ResultTopContents: View {
    let model: FeedbackResultModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("피드백 결과 요약")
                .font(.headingBold28)
                .foregroundStyle(.normalBlack900)
            
            ResultSummaryGridView(model: model)
        }
    }
}

struct ResultSummaryGridView: View {
    let model: FeedbackResultModel
    
    var body: some View {
        HStack(spacing: 16) {
            // 왼쪽
            VStack(spacing: 16) {
                // 왼쪽 상단: 스크립트 제목, 피드백 회차
                HStack(spacing: 16) {
                    DiagonalLayoutCard(title: "스크립트 제목") {
                            Text(model.scriptTitle)
                                .font(.subbodyBold24)
                    }
                    .cardBordered(padding: 24, cornerRadius: 10)
                    .frame(maxWidth: .infinity)
                    
                    DiagonalLayoutCard(title: "피드백 회차") {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(model.feedbackNumber)")
                                .font(.subtitleBold32)
                            
                            Text("회")
                                .font(.calloutRegular20)
                        }
                    }
                    .cardBordered(padding: 24, cornerRadius: 10)
                    .frame(maxWidth: 192)
                }
                .frame(maxWidth: .infinity)
                
                // 왼쪽 하단: 총 녹음 시간, 누락∙대체∙추가된 단어
                HStack(spacing: 16) {
                    DiagonalLayoutCard(title: "총 녹음 시간") {
                            Text(model.totalRecordingTime.toMMSSms())
                                .font(.subbodyBold24)
                    }
                    .cardBordered(padding: 24, cornerRadius: 10)
                    .frame(maxWidth: .infinity)
                    
                    DiagonalLayoutCard(title: "누락된 단어") {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(model.missingCount)")
                                .font(.subbodyBold24)
                            
                            Text("개")
                                .font(.calloutRegular16)
                        }
                    }
                    .cardBordered(padding: 24, cornerRadius: 10)
                    .frame(maxWidth: 150)
                    
                    DiagonalLayoutCard(title: "대체된 단어") {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(model.replacedCount)")
                                .font(.subbodyBold24)
                            
                            Text("개")
                                .font(.calloutRegular16)
                        }
                    }
                    .cardBordered(padding: 24, cornerRadius: 10)
                    .frame(maxWidth: 150)
                    
                    DiagonalLayoutCard(title: "추가된 단어") {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(model.extraCount)")
                                .font(.subbodyBold24)
                            
                            Text("개")
                                .font(.calloutRegular16)
                        }
                    }
                    .cardBordered(padding: 24, cornerRadius: 10)
                    .frame(maxWidth: 150)
                }
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // 오른쪽: 종합 평가 점수
            DiagonalLayoutCard(title: "종합 평가 점수") {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(Int(model.accuracy * 100))")
                        .font(.labelMedium64)
                    
                    Text("%")
                        .font(.bodyRegular24)
                }
            }
            .cardBordered(padding: 24, cornerRadius: 10)
            .frame(maxWidth: 242, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview

#Preview("일반 피드백 요약") {
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
    
    return ResultTopContents(model: model)
}

#Preview("완벽한 발음 요약") {
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
    
    return ResultTopContents(model: perfectModel)
}
