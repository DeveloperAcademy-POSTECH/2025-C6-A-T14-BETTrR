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
                CustomFlowLayout(horizontalSpacing: 12, verticalSpacing: 5) {
                    ForEach(sentence.chunks, id: \.orderIndex) { chunk in
                        let chunkID = ChunkIdentifier(sentenceIndex: sentence.orderIndex, chunkIndex: chunk.orderIndex)
                        
                        ScriptTextView(
                            text: chunk.englishText,
                            font: .bodyRegular28,
                            isBackground: true,
                            isHidden: viewModel.hiddenEngChunks.contains(chunkID),
                            isHighlighted: viewModel.tappedPlaybackText == chunk.englishText,
                            isVisible: true,
                            onTap: {
                                viewModel.handleChunkTap(chunk: chunk, identifier: chunkID)
                            }
                        )

                        if chunk.orderIndex != lastChunkIndex {
                            chunkSeparatorText(size: 35, isKoreanVisible: true)
                        }
                    }
                }
                
                // 2. 한국어 청크 라인
                    CustomFlowLayout(horizontalSpacing: 0, verticalSpacing: 5) {
                        ForEach(sentence.chunks, id: \.orderIndex) { chunk in
                            let chunkID = ChunkIdentifier(sentenceIndex: sentence.orderIndex, chunkIndex: chunk.orderIndex)
                            
                            ScriptTextView(
                                text: chunk.koreanText,
                                font: .calloutRegular16,
                                isBackground: false,
                                isHidden: viewModel.hiddenKorChunks.contains(chunkID),
                                isHighlighted: false,
                                isVisible: viewModel.isKoreanVisible,
                                onTap: {
                                    viewModel.handleKorChunkTap(chunk: chunk, identifier: chunkID)
                                }
                            )
                            
                            if chunk.orderIndex != lastChunkIndex {
                                chunkSeparatorText(size: 20, isKoreanVisible: viewModel.isKoreanVisible)
                            }
                        }
                    }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    @ViewBuilder
    private func chunkSeparatorText(size: CGFloat, isKoreanVisible: Bool) -> some View {
        Text("/")
            .font(.system(size: size))
            .foregroundStyle(isKoreanVisible ? .G_1 : .clear)
    }
}
