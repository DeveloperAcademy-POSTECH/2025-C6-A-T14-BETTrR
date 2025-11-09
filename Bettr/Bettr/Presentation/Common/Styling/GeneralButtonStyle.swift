//
//  ButtonStyle.swift
//  Bettr
//
//  Created by 길정수 on 11/9/25.
//

import SwiftUI

struct GeneralButtonStyle: ButtonStyle {
    var backgroundColor: Color
    var foregroundColor: Color
    var font: Font
    var cornerRadius: CGFloat = 50
    var paddingHorizontal: CGFloat = 16
    var paddingVertical: CGFloat = 16
    
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        // 비활성화 상태일 때 색상 처리
        let currentBackgroundColor = isEnabled ? backgroundColor : .W_1
        let currentForegroundColor = isEnabled ? foregroundColor : .gray.opacity(0.2)

        configuration.label
            .font(font)
            .padding(.horizontal, paddingHorizontal)
            .padding(.vertical, paddingVertical)
            .background(currentBackgroundColor)
            .foregroundStyle(currentForegroundColor)
            .cornerRadius(cornerRadius)
            // 눌렸을 때(isPressed) 효과
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == GeneralButtonStyle {
    
    static var standardActive: GeneralButtonStyle {
        GeneralButtonStyle(
            backgroundColor: .PP_1,
            foregroundColor: .W_1,
            font: .headline,
        )
    }
}
