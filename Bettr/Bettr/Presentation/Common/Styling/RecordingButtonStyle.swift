//
//  RecordingButtonStyle.swift
//  Bettr
//
//  Created by 길정수 on 11/11/25.
//

import SwiftUI

struct RecordingButtonStyle: ButtonStyle {
    var isRecording: Bool
    
    @Environment(\.isEnabled) private var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        let backgroundColor: Color
        
        if !isEnabled {
            // 비활성화 색상
            backgroundColor = Color.defaultWhite50
        } else if isRecording {
            // 녹음중 색상
            backgroundColor = Color.alertRed01
        } else {
            // 기본 색상
            backgroundColor = Color.primaryBlue500
        }
        
        return configuration.label
            .font(.labelRegular48)
            .foregroundStyle(isEnabled ? .defaultWhite50 : .primaryBlue50)
            .frame(width: 160, height: 160)
            .background(backgroundColor)
            .clipShape(Circle())
            .glassEffect()
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(duration: 0.2), value: configuration.isPressed)
    }
}

struct SecondaryRecordingButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.labelRegular48)
            .foregroundStyle(isEnabled ? .secondaryBlue700 : .primaryBlue50)
            .frame(width: 160, height: 160)
            .background(.defaultWhite50)
            .clipShape(Circle())
            .glassEffect()
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(duration: 0.2), value: configuration.isPressed)
    }
}
