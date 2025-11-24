//
//  HighlightedSentence.swift
//  Bettr
//
//  Created by 길정수 on 11/4/25.
//

import SwiftUI

/// '틀린 문장 모아보기'의 오른쪽에 표시될, 스타일이 적용된 '사용자의 발화' 스크립트 뷰입니다.
/// CustomFlowLayout을 사용하여 단어를 배치하고, .missing 단어는 회색으로, .extra 단어는 흐린 파란색과 취소선으로, .replaced된 단어는 빨간색으로 표시합니다.
struct UserSpeechSentenceView: View {
    let diffs: [WordDiff]
    
    private let matchedColor = Color(.normalBlack900)
    private let missingWordColor = Color(.normalGray600)
    private let extraWordColor = Color(.primaryBlue500)
    private let replacedWordColor = Color(.alertRed01)
    
    var body: some View {
        CustomFlowLayout(horizontalSpacing: 5, verticalSpacing: 3) {
            ForEach(Array(diffs.enumerated()), id: \.offset) { index, diff in
                speechWordView(for: diff)
            }
        }
        .font(.subbodyRegular20)
    }
    
    @ViewBuilder
    private func speechWordView(for diff: WordDiff) -> some View {
        switch diff {
        case .matched(let word):
            Text(word)
                .foregroundStyle(matchedColor)
        case .missing(let expected):
            Text(expected)
                .foregroundStyle(missingWordColor)
        case .extra(let actual):
            Text(actual)
                .foregroundStyle(extraWordColor)
                .strikethrough(color: extraWordColor)
        case .replaced(_, let actual):
            Text(actual)
                .bold()
                .foregroundStyle(replacedWordColor)
        }
    }
}
