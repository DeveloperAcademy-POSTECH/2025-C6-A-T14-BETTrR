//
//  FeedbackSummarySection.swift
//  Bettr
//
//  Created by 길정수 on 11/12/25.
//

import SwiftUI

struct FeedbackSummarySection: View {
    let model: FeedbackResultModel
    
    var body: some View {
        TitledSection.large(title: "피드백 결과 요약") {
            ViewThatFits {
                fullLayout
                compactLayout
            }
        }
    }
}

// MARK: - Layouts (Private)

private extension FeedbackSummarySection {
    var fullLayout: some View {
        HStack(spacing: 16) {
            // 왼쪽 그룹
            VStack(spacing: 16) {
                // 상단: 제목 + 회차
                HStack(spacing: 16) {
                    scriptTitleCard.frame(maxWidth: .infinity)
                    feedbackCountCard.frame(maxWidth: 192)
                }
                .frame(maxWidth: .infinity)
                
                // 하단: 시간 + 단어 카운트 3종
                HStack(spacing: 16) {
                    timeCard.frame(maxWidth: .infinity)
                    wordCountCards(maxWidth: 150)
                }
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // 오른쪽: 점수
            scoreCard(font: .labelMedium64)
                .frame(maxWidth: 242, maxHeight: .infinity)
        }
        .frame(maxHeight: 242)
    }
    
    var compactLayout: some View {
        VStack(spacing: 16) {
            // 상단: 제목
            scriptTitleCard
                .frame(maxWidth: .infinity, maxHeight: 120)
            
            // 하단 그룹
            HStack(spacing: 16) {
                // 왼쪽: 시간/회차 + 단어 카운트 3종
                VStack(spacing: 16) {
                    HStack(spacing: 16) {
                        timeCard
                        feedbackCountCard
                    }
                    
                    HStack(spacing: 16) {
                        wordCountCards(maxWidth: nil)
                    }
                }
                .layoutPriority(1)
                
                // 오른쪽: 점수
                scoreCard(font: .labelMedium48)
                    .frame(maxWidth: 242)
                    .layoutPriority(0)
            }
            .frame(maxHeight: 242)
        }
    }
}

// MARK: - Components (Builders)
private extension FeedbackSummarySection {
    @ViewBuilder
    func wordCountCards(maxWidth: CGFloat?) -> some View {
        statCard(title: "누락된 단어", count: model.missingCount, maxWidth: maxWidth)
        statCard(title: "대체된 단어", count: model.replacedCount, maxWidth: maxWidth)
        statCard(title: "추가된 단어", count: model.extraCount, maxWidth: maxWidth)
    }
    
    var scriptTitleCard: some View {
        DiagonalLayoutCard(title: "스크립트 제목") {
            Text(model.scriptTitle)
                .font(.subbodyBold24)
                .fixedSize(horizontal: true, vertical: false)
        }
        .cardBordered(padding: 24, cornerRadius: 10)
    }
    
    var feedbackCountCard: some View {
        DiagonalLayoutCard(title: "피드백 회차") {
            unitText(value: "\(model.feedbackNumber)", unit: "회", valueFont: .subtitleBold32, unitFont: .calloutRegular20)
        }
        .cardBordered(padding: 24, cornerRadius: 10)
    }
    
    var timeCard: some View {
        DiagonalLayoutCard(title: "총 녹음 시간") {
            Text(model.totalRecordingTime.toMMSSms())
                .font(.subbodyBold24)
                .fixedSize(horizontal: true, vertical: false)
        }
        .cardBordered(padding: 24, cornerRadius: 10)
    }
    
    func scoreCard(font: Font) -> some View {
        DiagonalLayoutCard(title: "종합 평가 점수") {
            unitText(value: "\(Int(model.accuracy * 100))", unit: "%", valueFont: font, unitFont: .bodyRegular24)
        }
        .cardBordered(padding: 24, cornerRadius: 10)
    }
    
    // 헬퍼: 숫자 + 단위 (예: 5개, 1회)
    func statCard(title: String, count: Int, maxWidth: CGFloat?) -> some View {
        DiagonalLayoutCard(title: title) {
            unitText(value: "\(count)", unit: "개", valueFont: .subbodyBold24, unitFont: .calloutRegular16)
        }
        .cardBordered(padding: 24, cornerRadius: 10)
        .frame(maxWidth: maxWidth)
    }
    
    // 헬퍼: 텍스트 조합 (BaseLine 정렬)
    func unitText(value: String, unit: String, valueFont: Font, unitFont: Font) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(value).font(valueFont)
            Text(unit).font(unitFont)
        }
        .fixedSize(horizontal: true, vertical: false)
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
    
    return FeedbackSummarySection(model: model)
        .safeAreaPadding(.horizontal, 84)
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
    
    return FeedbackSummarySection(model: perfectModel)
        .safeAreaPadding(.horizontal, 84)
}
