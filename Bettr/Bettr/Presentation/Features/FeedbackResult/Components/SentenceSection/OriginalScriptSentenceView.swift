//
//  OriginalScriptSentence.swift
//  Bettr
//
//  Created by 길정수 on 11/13/25.
//

import SwiftUI

/// '틀린 문장 모아보기'의 왼쪽에 표시될, 스타일이 적용된 '원본' 스크립트 뷰
/// CustomFlowLayout을 사용하여 단어를 배치하고, .replaced된 단어에 bold 처리
struct OriginalScriptSentenceView: View {
    let diffs: [WordDiff]
     
    var body: some View {
        CustomFlowLayout(horizontalSpacing: 5, verticalSpacing: 4) {
            ForEach(Array(diffs.enumerated()), id: \.offset) { index, diff in
                originalWordView(for: diff)
            }
        }
        .font(.subbodyRegular20)
    }
    
    @ViewBuilder
    private func originalWordView(for diff: WordDiff) -> some View {
        switch diff {
        case .matched(let word):
            Text(word)
        case .missing(let expected):
            Text(expected)
        case .extra:
            EmptyView()
        case .replaced(let expected, _):
            Text(expected)
                .bold()
        }
    }
}
