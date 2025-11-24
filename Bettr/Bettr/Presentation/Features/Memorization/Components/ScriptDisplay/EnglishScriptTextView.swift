//
//  EnglishScriptTextView.swift
//  Bettr
//
//  Created by 길정수 on 11/3/25.
//

import SwiftUI

struct EnglishScriptTextView: View {
    let text: String
    let isHidden: Bool
    let onTap: () -> Void
    let sentenceIndex: Int?
    let viewID: PlaybackTargetID
    
    var chunkOffset: Int? = nil
    
    @Environment(AudioPlaybackService.self) private var audioService
    
    private let unspokenColor = Color.normalGray600
    private let spokenColor = Color.normalBlack900
    
    private var attributedText: AttributedString {
        var attrString = AttributedString(text)
        
        // 가리기: 투명 처리 후 즉시 반환
        if isHidden {
            attrString.foregroundColor = .clear
            return attrString
        }
        
        // 기본 색상: 회색 or 검은색 (상황에 따라 결정)
        let baseColor = baseForegroundColor
        attrString.foregroundColor = baseColor
        
        // 재생 중일 때만 하이라이팅
        if audioService.isPlaybackActive || audioService.isPaused {
            return applyHighlighting(to: attrString)
        }
        
        return attrString
    }
    
    // 기본 색상 (하이라이팅 전, 문장 단위로 기본 색상을 지정)
    private var baseForegroundColor: Color {
        // 재생 중이 아닐 때: 검은색
        guard audioService.isPlaybackActive || audioService.isPaused else { return spokenColor }
        
        if audioService.currentPlaybackMode == .multi {
            // A. 전체 재생
            guard let currentPlayingIndex = audioService.currentMultiSentenceIndex,
                  let myIndex = sentenceIndex else { return unspokenColor }
            
            if myIndex < currentPlayingIndex {
                return spokenColor   // 이미 지나간 문장: 검은색
            } else if myIndex == currentPlayingIndex {
                return unspokenColor // 지금 재생 중인 문장: 회색
            } else {
                return unspokenColor // 아직 안 온 문장: 회색
            }
        } else {
            // B. 부분 재생
            // 재생 중인 문장(청크)는 회색, 아니면 검은색
            return (audioService.currentPlaybackID == viewID) ? unspokenColor : spokenColor
        }
    }
    
    // 하이라이팅 (실제 읽고 있는 부분만 검은색)
    private func applyHighlighting(to source: AttributedString) -> AttributedString {
        var attr = source
        
        if audioService.currentPlaybackMode == .multi {
            // A. 전체 재생
            if let currentPlayingIndex = audioService.currentMultiSentenceIndex,
               let myIndex = sentenceIndex,
               myIndex == currentPlayingIndex, // 내 문장이 재생 중일 때만
               let globalRange = audioService.currentSpokenRange {
                
                let spokenEndIndex = globalRange.location + globalRange.length
                let myStartOffset = chunkOffset ?? 0
                
                // 내 청크 범위 안으로 재생 지점이 들어왔는지 확인
                if spokenEndIndex > myStartOffset {
                    let highlightLength = min(spokenEndIndex - myStartOffset, text.count)
                    
                    if highlightLength > 0,
                       let stringIndex = text.index(text.startIndex, offsetBy: highlightLength, limitedBy: text.endIndex),
                       let attrIndex = AttributedString.Index(stringIndex, within: attr) {
                        
                        attr[attr.startIndex..<attrIndex].foregroundColor = spokenColor
                    }
                }
            }
        } else {
            // B. 부분 재생
            if audioService.currentPlaybackID == viewID,
               let nsRange = audioService.currentSpokenRange,
               let swiftRange = Range(nsRange, in: text),
               let attrRange = Range(swiftRange, in: attr) {
                
                attr[attr.startIndex..<attrRange.upperBound].foregroundColor = spokenColor
            }
        }
        
        return attr
    }
    
    var body: some View {
        Button(action: onTap) {
            Text(attributedText)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .font(.bodyRegular24)
                .opacity(isHidden ? 0 : 1)
        }
        .buttonStyle(ScriptButtonStyle())
        .hoverEffect(.lift)
    }
}

struct ScriptButtonStyle: ButtonStyle {
    private let cornerRadius: CGFloat = 2
    private let shadowColor = Color.normalBlack900.opacity(0.2)
    private let shadowOffset: CGFloat = 2
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background {
                RoundedRectangle(cornerRadius: 2)
                    .fill(.normalGray200)
                    .shadow(
                        color: configuration.isPressed ? .clear : shadowColor,
                        radius: configuration.isPressed ? 0 : shadowOffset,
                        x: configuration.isPressed ? 0 : shadowOffset,
                        y: configuration.isPressed ? 0 : shadowOffset
                    )
            }
            .offset(
                x: configuration.isPressed ? shadowOffset : 0,
                y: configuration.isPressed ? shadowOffset : 0
            )
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}
