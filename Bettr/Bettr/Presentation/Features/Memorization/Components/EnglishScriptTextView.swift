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
    
    @Environment(AudioPlaybackService.self) private var audioService
    
    private let unspokenColor = Color.normalGray600
    private let spokenColor = Color.normalBlack900
    
    private var attributedText: AttributedString {
        var attrString = AttributedString(text)
        
        // 가리기 상태
        if isHidden {
            attrString.foregroundColor = .clear
            return attrString
        }
        
        let isMultiSentenceMode = audioService.currentPlayingSentenceIndex != nil
        
        let defaultColor: Color
        
        if audioService.isPlaying || audioService.isPaused {
            // 재생 또는 일시정지 활성화 상태
            
            if isMultiSentenceMode {
                // A. 전체 재생 모드 (완료된 문장과 진행 중/대기 문장 분리)
                
                let isSentenceCompleted: Bool
                if let currentPlayingIndex = audioService.currentPlayingSentenceIndex, let myIndex = sentenceIndex {
                    isSentenceCompleted = myIndex < currentPlayingIndex
                } else {
                    isSentenceCompleted = false
                }
                
                defaultColor = isSentenceCompleted ? spokenColor : unspokenColor
                
            } else {
                // B. 단일 재생 모드 (청크/문장 탭 재생)
                
                // 현재 발화 중인 텍스트만 회색으로 설정 (하이라이트 배경)
                if audioService.currentSpokenTextID == text {
                    defaultColor = unspokenColor
                } else {
                    // 발화 중이 아닌 다른 모든 문장/청크는 검은색 유지
                    defaultColor = spokenColor
                }
            }
            
        } else {
            // C. 정지 상태 (전체 검은색)
            defaultColor = spokenColor
        }
        
        // 2. 기본 색상 설정
        attrString.foregroundColor = defaultColor
        
        // 3. 발화 중인 단어 하이라이트 (검은색으로 덮어쓰기)
        if audioService.currentSpokenTextID == text,
           let nsRange = audioService.currentSpokenRange,
           let swiftRange = Range(nsRange, in: text) {
            
            if let attrRange = Range(swiftRange, in: attrString) {
                // 발화된 부분만 검은색(spoken)으로 덮어쓰기
                attrString[attrString.startIndex..<attrRange.upperBound].foregroundColor = spokenColor
            }
        }
        
        return attrString
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
