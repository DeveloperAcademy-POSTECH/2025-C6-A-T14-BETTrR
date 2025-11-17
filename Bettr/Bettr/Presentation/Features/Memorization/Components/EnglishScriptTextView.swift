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
    let isHighlighted: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(text)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .font(.bodyRegular24)
                .opacity(isHidden ? 0 : 1)
                .foregroundColor(.normalBlack900)
        }
        .buttonStyle(ScriptButtonStyle())
        .overlay {
            RoundedRectangle(cornerRadius: 2)
                .stroke(isHighlighted ? .primaryBlue300 : .clear, lineWidth: 4)
        }
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
                        // ◀︎◀︎ 핵심 로직
                        color: configuration.isPressed ? .clear : normalShadowColor,
                        radius: configuration.isPressed ? 0 : normalShadowRadius,
                        x: configuration.isPressed ? 0 : normalShadowX,
                        y: configuration.isPressed ? 0 : normalShadowY
                    )
            )
            .offset(y: configuration.isPressed ? normalShadowY : 0)
    }
}
