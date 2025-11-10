//
//  ButtonStyle.swift
//  Bettr
//
//  Created by 길정수 on 11/9/25.
//

import SwiftUI

struct GeneralButtonStyle: ButtonStyle {
    var font: Font = .labelBold16
    var cornerRadius: CGFloat = 50
    var paddingVertical: CGFloat = 16
    var width: CGFloat = 160
    
    @Environment(\.isEnabled) private var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        // 비활성화 상태일 때 색상 처리
        let currentBackgroundColor = isEnabled ? Color.primaryBlue500 : Color.defaultWhite50
        let currentForegroundColor = isEnabled ? Color.defaultWhite50 : .gray.opacity(0.2)
        
        configuration.label
            .font(font)
            .padding(.vertical, paddingVertical)
            .frame(width: width)
            .foregroundStyle(currentForegroundColor)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(currentBackgroundColor)
            )
    }
}

extension ButtonStyle where Self == GeneralButtonStyle {
    
    /// 기본 버튼 스타일 (너비 160)
    static var general: GeneralButtonStyle {
        GeneralButtonStyle()
    }
}
