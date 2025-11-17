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
        
        // 현재 이 텍스트가 재생 중인 경우
        if audioService.currentSpokenTextID == text,
           let nsRange = audioService.currentSpokenRange,
           let swiftRange = Range(nsRange, in: text) { // NSRange -> Swift Range
            
            attrString.foregroundColor = unspokenColor
            
            // Swift Range -> AttributedString.Index Range
            if let attrRange = Range(swiftRange, in: attrString) {
                // "말한 부분" (시작~현재 위치)만 검은색(spoken)으로 덮어쓰기
                attrString[attrString.startIndex..<attrRange.upperBound].foregroundColor = spokenColor
            }
            
        } else { // 재생 중이 아닐 때 (기본 상태)
            attrString.foregroundColor = spokenColor
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
                .animation(.linear(duration: 0.1), value: attributedText)
        }
        .buttonStyle(ScriptButtonStyle())
        .hoverEffect(.lift)
    }
}

struct ScriptButtonStyle: ButtonStyle {
    
    let normalShadowColor = Color.normalBlack900.opacity(0.2)
    let normalShadowRadius: CGFloat = 2
    let normalShadowX: CGFloat = 2
    let normalShadowY: CGFloat = 2
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 2)
                    .fill(.normalGray200)
                    .shadow(
                        color: configuration.isPressed ? .clear : normalShadowColor,
                        radius: configuration.isPressed ? 0 : normalShadowRadius,
                        x: configuration.isPressed ? 0 : normalShadowX,
                        y: configuration.isPressed ? 0 : normalShadowY
                    )
            )
            .offset(y: configuration.isPressed ? normalShadowY : 0)
    }
}
