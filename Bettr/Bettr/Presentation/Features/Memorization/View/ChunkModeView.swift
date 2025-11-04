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
            
            VStack(alignment: .leading, spacing: 8) {
                // 1. 영어 청크 라인
                CustomFlowLayout(horizontalSpacing: 0, verticalSpacing: 5) {
                    ForEach(sentence.chunks, id: \.orderIndex) { chunk in
                        let chunkID = ChunkIdentifier(sentenceIndex: sentence.orderIndex, chunkIndex: chunk.orderIndex)
                        
                        ScriptTextView(
                            text: chunk.englishText,
                            fontSize: 30,
                            isHidden: viewModel.hiddenEngChunks.contains(chunkID),
                            isHighlighted: viewModel.tappedPlaybackText == chunk.englishText,
                            onTap: {
                                viewModel.handleChunkTap(chunk: chunk, identifier: chunkID)
                            }
                        )
                        
                        if chunk.orderIndex != lastChunkIndex {
                            chunkSeparatorText(size: 33)
                        }
                    }
                }
                
                // 2. 한국어 청크 라인
                if viewModel.langMode == .engKor {
                    CustomFlowLayout(horizontalSpacing: 0, verticalSpacing: 5) {
                        ForEach(sentence.chunks, id: \.orderIndex) { chunk in
                            let chunkID = ChunkIdentifier(sentenceIndex: sentence.orderIndex, chunkIndex: chunk.orderIndex)
                            
                            ScriptTextView(
                                text: chunk.koreanText,
                                fontSize: 20,
                                isHidden: viewModel.hiddenKorChunks.contains(chunkID),
                                isHighlighted: false,
                                onTap: {
                                    viewModel.handleKorChunkTap(chunk: chunk, identifier: chunkID)
                                }
                            )
                            
                            if chunk.orderIndex != lastChunkIndex {
                                chunkSeparatorText(size: 20)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    @ViewBuilder
    private func chunkSeparatorText(size: CGFloat) -> some View {
        Text(" / ")
            .font(.system(size: size))
            .foregroundColor(.gray.opacity(0.7))
    }
}
