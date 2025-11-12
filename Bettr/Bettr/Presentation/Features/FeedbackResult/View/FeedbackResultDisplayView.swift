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
        ScrollView {
            VStack(alignment: .leading, spacing: 64) {
                // 상단 섹션
                VStack(alignment: .leading, spacing: 24) {
                    Text("피드백 결과 요약")
                        .font(.headingBold28)
                        .foregroundStyle(.normalBlack900)
                    
                    HStack(spacing: 16) {
                        VStack(spacing: 16) {
                            HStack(spacing: 16) {
                                DiagonalLayoutCard(title: "스크립트 제목") {
                                    HStack(alignment: .bottom, spacing: 4) {
                                        Text(model.scriptTitle)
                                            .font(.subbodyBold24)
                                    }
                                }
                                .cardBordered(padding: 24)
                                
                                DiagonalLayoutCard(title: "피드백 회차") {
                                    HStack(alignment: .bottom, spacing: 4) {
                                        Text("\(model.feedbackNumber)")
                                            .font(.subtitleBold32)
                                        
                                        Text("번")
                                            .font(.calloutRegular20)
                                    }
                                }
                                .cardBordered(padding: 24)
                                .frame(maxWidth: 192)
                            }
                            .frame(maxHeight: 116)
                            
                            HStack(spacing: 16) {
                                DiagonalLayoutCard(title: "총 녹음 시간") {
                                    HStack(alignment: .bottom, spacing: 4) {
                                        Text(model.totalRecordingTime.toMMSSms())
                                            .font(.subbodyBold24)
                                    }
                                }
                                .cardBordered(padding: 24)
                                .frame(minWidth: 200)
                                
                                DiagonalLayoutCard(title: "누락된 단어") {
                                    HStack(alignment: .bottom, spacing: 4) {
                                        Text("\(model.missingCount)")
                                            .font(.subbodyBold24)
                                        
                                        Text("개")
                                            .font(.calloutRegular16)
                                    }
                                }
                                .cardBordered(padding: 24)
                                .frame(maxWidth: 150)
                                
                                DiagonalLayoutCard(title: "대체된 단어") {
                                    HStack(alignment: .bottom, spacing: 4) {
                                        Text("\(model.replacedCount)")
                                            .font(.subbodyBold24)
                                        
                                        Text("개")
                                            .font(.calloutRegular16)
                                    }
                                }
                                .cardBordered(padding: 24)
                                .frame(maxWidth: 150)
                                
                                DiagonalLayoutCard(title: "추가된 단어") {
                                    HStack(alignment: .bottom, spacing: 4) {
                                        Text("\(model.extraCount)")
                                            .font(.subbodyBold24)
                                        
                                        Text("개")
                                            .font(.calloutRegular16)
                                    }
                                }
                                .cardBordered(padding: 24)
                                .frame(maxWidth: 150)
                            }
                            .frame(maxHeight: 120)
                        }
                        
                        DiagonalLayoutCard(title: "종합 평가 점수") {
                            HStack(alignment: .bottom, spacing: 4) {
                                Text("\(Int(model.accuracy * 100))")
                                    .font(.labelMedium64)
                                
                                Text("%")
                                    .font(.bodyRegular24)
                            }
                        }
                        .cardBordered(padding: 24)
                        .frame(maxWidth: 229, maxHeight: 242)
                    }
                }
                                
                // 하단 섹션
                VStack(alignment: .leading, spacing: 24) {
                    Text("틀린 문장 모아보기")
                        .font(.headingBold28)
                        .foregroundStyle(.normalBlack900)
                    
                    if model.filteredSentenceDiffs.isEmpty {
                        Text("틀린 문장이 하나도 없습니다.")
                            .font(.labelBold16)
                            .foregroundColor(.normalBlack900)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                            .cardBorderedFilled(padding: 36)
                    } else {
                        VStack(spacing: 0) {
                            ForEach(model.filteredSentenceDiffs, id: \.index) { (originalIndex, sentenceData) in
                                HStack(spacing: 0) {
                                    HighlightedTextView(diffs: sentenceData.diffs)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(36)
                                    
                                    Spacer()
                                    
                                    Divider()
                                        .foregroundStyle(.primaryBlue200)
                                    
                                    Spacer()
                                    
                                    Text(sentenceData.original)
                                        .font(.subbodyRegular20)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(36)
                                }
                            }
                        }
                        .cardBordered(padding: 0)
                    }
                }
            }
            .safeAreaPadding(.horizontal, 120)
        }
        .safeAreaPadding(.top, 36)
        .safeAreaPadding(.bottom, 48)
    }
}

struct ResultTopContents: View {
    var body: some View {
        
    }
}

struct ResultBottomContents: View {
    var body: some View {
        
    }
}

// MARK: - Preview

#Preview("일반 피드백") {
    // Preview도 모델을 생성하여 주입합니다.
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
