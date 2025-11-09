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
                ScriptTextView(
                    text: sentence.englishText,
                    font: .bodyRegular28,
                    isBackground: true,
                    isHidden: viewModel.hiddenEngSentences.contains(sentence.orderIndex),
                    isHighlighted: viewModel.tappedPlaybackText == sentence.englishText,
                    isVisible: true,
                    onTap: {
                        viewModel.handleSentenceTap(sentence: sentence)
                    }
                )
                
                // 2. 한국어 텍스트
                    ScriptTextView(
                        text: sentence.koreanText,
                        font: .calloutRegular16,
                        isBackground: false,
                        isHidden: viewModel.hiddenKorSentences.contains(sentence.orderIndex),
                        isHighlighted: false,
                        isVisible: viewModel.isKoreanVisible,
                        onTap: {
                            viewModel.handleKorSentenceTap(sentence: sentence)
                        }
                    )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
