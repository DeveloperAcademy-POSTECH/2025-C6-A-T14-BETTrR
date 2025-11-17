//
//  ChunkModeView.swift
//  Bettr
//
//  Created by 길정수 on 11/3/25.
//

import SwiftUI

struct ChunkModeView: View {
    @Bindable var viewModel: MemorizationViewModel
    
    var body: some View {
        ForEach(viewModel.scriptData?.sentences ?? [], id: \.orderIndex) { sentence in
            
            VStack(alignment: .leading, spacing: 6) {
                
                englishChunkLine(for: sentence)
                
                koreanChunkLine(for: sentence)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .id(sentence.orderIndex)
        }
    }
    
    private func englishChunkLine(for sentence: SentenceData) -> some View {
        let lastChunkIndex = sentence.chunks.last?.orderIndex
        
        return CustomFlowLayout(horizontalSpacing: 12, verticalSpacing: 8) {
            ForEach(sentence.chunks, id: \.orderIndex) { chunk in
                
                let chunkID = ChunkIdentifier(sentenceIndex: sentence.orderIndex, chunkIndex: chunk.orderIndex)
                
                EnglishScriptTextView(
                    text: chunk.englishText,
                    isHidden: viewModel.interactionState.hiddenEngChunks.contains(chunkID),
                    onTap: { handleChunkTap(chunk: chunk, identifier: chunkID) }
                )
                
                if chunk.orderIndex != lastChunkIndex {
                    Image(.slashLarge)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 44)
                }
            }
        }
    }
    
    /// 한국어 청크 라인을 그리는 뷰
    private func koreanChunkLine(for sentence: SentenceData) -> some View {
        let lastChunkIndex = sentence.chunks.last?.orderIndex
        
        return CustomFlowLayout(horizontalSpacing: 0, verticalSpacing: 0) {
            ForEach(sentence.chunks, id: \.orderIndex) { chunk in
                
                KoreanScriptTextView(
                    text: chunk.koreanText,
                    isVisible: viewModel.uiState.isKoreanVisible,
                )
                
                if chunk.orderIndex != lastChunkIndex {
                    Image(.slashSmall)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 9, height: 14)
                        .opacity(viewModel.uiState.isKoreanVisible ? 1.0 : 0.0)
                }
            }
        }
    }
    
    /// 애니메이션 로직을 포함한 탭 핸들러
    private func handleChunkTap(chunk: ChunkData, identifier: ChunkIdentifier) {
        withAnimation(.easeInOut(duration: 0.02)) {
            viewModel.handleChunkTap(chunk: chunk, identifier: identifier)
        }
    }
}
