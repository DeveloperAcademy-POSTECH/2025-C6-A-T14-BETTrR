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
                    onTap: { handleSentenceTap(sentence: sentence) }
                )
                
                KoreanScriptTextView(
                    text: sentence.koreanText,
                    isVisible: viewModel.uiState.isKoreanVisible,
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .id(sentence.orderIndex)
        }
    }
    
    /// 애니메이션 로직을 포함한 탭 핸들러
    private func handleSentenceTap(sentence: SentenceData) {
        withAnimation(.easeInOut(duration: 0.02)) {
            viewModel.handleSentenceTap(sentence: sentence)
        }
    }
}
