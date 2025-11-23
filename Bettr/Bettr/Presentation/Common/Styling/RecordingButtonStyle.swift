//
//  RecordingButtonStyle.swift
//  Bettr
//
//  Created by 길정수 on 11/11/25.
//

import SwiftUI

// 공통 스타일
private struct RecordingButtonBaseModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.labelRegular48)
            .aspectRatio(1, contentMode: .fit)
            .padding(40)
            .frame(maxWidth: 140, maxHeight: 140)
    }
}

// 메인 버튼 (빨강, 파랑, 비활성화)
struct RecordToggleButtonStyle: ButtonStyle {
    var isRecording: Bool
    
    @Environment(\.isEnabled) private var isEnabled
    
    private var backgroundColor: Color {
        if !isEnabled {
            return .defaultWhite50
        } else if isRecording {
            return .alertRed01
        } else {
            return .primaryBlue500
        }
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(isEnabled ? .defaultWhite50 : .primaryBlue50)
            .modifier(RecordingButtonBaseModifier())
            .background(backgroundColor)
            .clipShape(Circle())
            .contentShape(Circle())
            .glassEffect(.regular.interactive(true), in: Circle())
    }
}

// 보조 버튼
struct RecordCancelButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(isEnabled ? .secondaryBlue700 : .primaryBlue50)
            .modifier(RecordingButtonBaseModifier())
            .background(.defaultWhite50)
            .clipShape(Circle())
            .contentShape(Circle())
            .glassEffect(.regular.interactive(true), in: Circle())
    }
}
