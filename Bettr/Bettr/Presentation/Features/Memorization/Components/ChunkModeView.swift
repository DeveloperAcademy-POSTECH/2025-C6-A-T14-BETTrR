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
            let lastChunkIndex = sentence.chunks.last?.orderIndex
            
            VStack(alignment: .leading, spacing: 6) {
                // 1. 영어 청크 라인
                CustomFlowLayout(horizontalSpacing: 12, verticalSpacing: 8) {
                    ForEach(sentence.chunks, id: \.orderIndex) { chunk in
                        let chunkID = ChunkIdentifier(sentenceIndex: sentence.orderIndex, chunkIndex: chunk.orderIndex)
                        
                        EnglishScriptTextView(
                            text: chunk.englishText,
                            isHidden: viewModel.hiddenEngChunks.contains(chunkID),
                            isHighlighted: viewModel.tappedPlaybackText == chunk.englishText,
                            onTap: {
                                viewModel.handleChunkTap(chunk: chunk, identifier: chunkID)
                            }
                        )
                        
                        if chunk.orderIndex != lastChunkIndex {
                            Image(.slashLarge)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 14, height: 44)
                        }
                    }
                }
                
                // 2. 한국어 청크 라인
                CustomFlowLayout(horizontalSpacing: 0, verticalSpacing: 0) {
                    ForEach(sentence.chunks, id: \.orderIndex) { chunk in
                        
                        KoreanScriptTextView(
                            text: chunk.koreanText,
                            isVisible: viewModel.isKoreanVisible,
                        )
                        
                        if chunk.orderIndex != lastChunkIndex {
                            Image(.slashSmall)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 9, height: 14)
                                .opacity(viewModel.isKoreanVisible ? 1.0 : 0.0)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
