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
            VStack(alignment: .leading, spacing: 6) {
                
                EnglishScriptTextView(
                    text: sentence.englishText,
                    isHidden: viewModel.isSentenceHidden(sentence.orderIndex),
                    isHighlighted: viewModel.isTextHighlighted(sentence.englishText),
                    onTap: {
                        viewModel.handleSentenceTap(sentence: sentence)
                    }
                )
                
                KoreanScriptTextView(
                    text: sentence.koreanText,
                    isVisible: viewModel.uiState.isKoreanVisible,
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
