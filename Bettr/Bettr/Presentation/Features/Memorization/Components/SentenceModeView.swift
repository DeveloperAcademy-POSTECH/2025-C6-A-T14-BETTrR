//
//  SentenceModeView.swift
//  Bettr
//
//  Created by 길정수 on 11/3/25.
//

import SwiftUI

struct SentenceModeView: View {
    @Bindable var viewModel: MemorizationViewModel

    var body: some View {
        ForEach(viewModel.scriptData?.sentences ?? [], id: \.orderIndex) { sentence in
            VStack(alignment: .leading, spacing: 12) {
                
                // 1. 영어 텍스트
                EnglishScriptTextView(
                    text: sentence.englishText,
                    isHidden: viewModel.hiddenEngSentences.contains(sentence.orderIndex),
                    isHighlighted: viewModel.tappedPlaybackText == sentence.englishText,
                    onTap: {
                        viewModel.handleSentenceTap(sentence: sentence)
                    }
                )
                
                // 2. 한국어 텍스트
                KoreanScriptTextView(
                        text: sentence.koreanText,
                        isVisible: viewModel.isKoreanVisible,
                    )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
