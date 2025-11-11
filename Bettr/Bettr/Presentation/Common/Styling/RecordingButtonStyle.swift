//
//  RecordingButtonStyle.swift
//  Bettr
//
//  Created by 길정수 on 11/11/25.
//

import SwiftUI

// 공통 스타일
private struct RecordingButtonBaseModifier: ViewModifier {
    let isPressed: Bool
    
    func body(content: Content) -> some View {
        content
            .font(.labelRegular48)
            .frame(width: 160, height: 160)
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(duration: 0.2), value: isPressed)
    }
}

// 메인 버튼 (빨강, 파랑, 비활성화)
struct RecordingButtonStyle: ButtonStyle {
    var isRecording: Bool
    
    @Environment(\.isEnabled) private var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        let backgroundColor: Color
        if !isEnabled {
            backgroundColor = Color.defaultWhite50
        } else if isRecording {
            backgroundColor = Color.alertRed01
        } else {
            backgroundColor = Color.primaryBlue500
        }
        
        return configuration.label
            .foregroundStyle(isEnabled ? .defaultWhite50 : .primaryBlue50)
            .modifier(RecordingButtonBaseModifier(isPressed: configuration.isPressed))
            .background(backgroundColor)
            .clipShape(Circle())
            .glassEffect()
    }
}

// 보조 버튼
struct SecondaryRecordingButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        
        return configuration.label
            .foregroundStyle(isEnabled ? .secondaryBlue700 : .primaryBlue50)
            .modifier(RecordingButtonBaseModifier(isPressed: configuration.isPressed))
            .background(.defaultWhite50)
            .clipShape(Circle())
            .glassEffect()
    }
}
