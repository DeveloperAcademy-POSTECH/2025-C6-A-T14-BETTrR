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
                    fontSize: 30,
                    // ⭐️ 모든 상태를 viewModel에서 직접 읽음
                    isHidden: viewModel.hiddenEngSentences.contains(sentence.orderIndex),
                    isHighlighted: viewModel.tappedPlaybackText == sentence.englishText,
                    onTap: {
                        viewModel.handleSentenceTap(sentence: sentence)
                    }
                )
                
                // 2. 한국어 텍스트
                if viewModel.langMode == .engKor {
                    ScriptTextView(
                        text: sentence.koreanText,
                        fontSize: 20,
                        isHidden: viewModel.hiddenKorSentences.contains(sentence.orderIndex),
                        isHighlighted: false,
                        onTap: {
                            viewModel.handleKorSentenceTap(sentence: sentence)
                        }
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
