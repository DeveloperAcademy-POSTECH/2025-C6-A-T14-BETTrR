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
    
    /// 영어 청크 라인을 그리는 뷰를 반환
    private func englishChunkLine(for sentence: SentenceData) -> some View {
        let lastChunkIndex = sentence.chunks.last?.orderIndex
        
        var currentOffset = 0
        
        // 각 청크가 문장 내 몇 번쨰 글자부터 시작하는 계산 (offset) -> 튜플 반환
        let chunksWithOffset = sentence.chunks.map { chunk -> (ChunkData, Int) in
            let offset = currentOffset
            
            currentOffset += chunk.englishText.count
            
            // 띄어쓰기 보정
            if sentence.englishText.count > currentOffset {
                let index = sentence.englishText.index(sentence.englishText.startIndex, offsetBy: currentOffset)
                if sentence.englishText[index] == " " {
                    currentOffset += 1
                }
            }
            
            return (chunk, offset)
        }
        
        return CustomFlowLayout(horizontalSpacing: 12, verticalSpacing: 8) {
            ForEach(chunksWithOffset, id: \.0.orderIndex) { (chunk, offset) in
                let chunkID = ChunkIdentifier(sentenceIndex: sentence.orderIndex, chunkIndex: chunk.orderIndex)
                
                EnglishScriptTextView(
                    text: chunk.englishText,
                    isHidden: viewModel.interactionState.hiddenEngChunks.contains(chunkID),
                    onTap: { viewModel.handleChunkTap(chunk: chunk, identifier: chunkID) },
                    sentenceIndex: sentence.orderIndex,
                    viewID: chunkID,
                    chunkOffset: offset
                )
                
                // 청크 사이 슬래시
                if chunk.orderIndex != lastChunkIndex {
                    Image(.slashLarge)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 44)
                }
            }
        }
    }
    
    /// 한국어 청크 라인을 그리는 뷰를 반환
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
}
