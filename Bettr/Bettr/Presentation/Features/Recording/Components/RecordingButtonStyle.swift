//
//  RecordingButtonStyle.swift
//  Bettr
//
//  Created by 길정수 on 11/11/25.
//

import SwiftUI

/// 모든 녹음 관련 버튼의 공통 레이아웃과 스타일을 정의하는 수정자
///
/// **적용 순서:**
/// 1. 폰트 및 프레임(레이아웃) 설정
/// 2. 배경색 적용 (`background`)
/// 3. 형태 잘라내기 (`clipShape`) 및 터치 영역 설정 (`contentShape`)
/// 4. 글래스 이펙트 적용
private struct RecordingButtonBaseModifier: ViewModifier {
    /// 버튼의 배경색 (상태에 따라 달라짐)
    let backgroundColor: Color
    
    func body(content: Content) -> some View {
        content
            .font(.labelRegular48)
            .aspectRatio(1, contentMode: .fit)
            .padding(40)
            .frame(maxWidth: 140, maxHeight: 140)
            .background(backgroundColor)
            .clipShape(Circle())
            .contentShape(Circle())
            .glassEffect(.regular.interactive(true), in: Circle())
    }
}

// MARK: - Button Styles

/// 녹음 화면의 왼쪽 **'재설정(Reset)'** 버튼 스타일
///
/// - **Active (활성)**: 흰색 배경 / 진한 파랑 아이콘 (`secondaryBlue700`)
/// - **Disabled (비활성)**: 흰색 배경 / 연한 파랑 아이콘 (`primaryBlue50`)
struct ResetButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(isEnabled ? .secondaryBlue700 : .primaryBlue50)
            .modifier(RecordingButtonBaseModifier(
                backgroundColor: .defaultWhite50
            ))
    }
}

/// 녹음 화면의 가운데 **'녹음/정지(Toggle)'** 버튼 스타일
///
/// - **Active (활성)**: `isRecording` 상태에 따라 배경색 변경
///   - 녹음 중 (`true`): 빨강 배경 (`alertRed01`)
///   - 대기 중 (`false`): 파랑 배경 (`primaryBlue500`)
/// - **Disabled (비활성)**: 흰색 배경 / 연한 파랑 아이콘 (`primaryBlue50`)
struct RecordToggleButtonStyle: ButtonStyle {
    let isRecording: Bool
    @Environment(\.isEnabled) private var isEnabled
    
    private var activeBackgroundColor: Color {
        isRecording ? .alertRed01 : .primaryBlue500
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(isEnabled ? .defaultWhite50 : .primaryBlue50)
            .modifier(RecordingButtonBaseModifier(
                backgroundColor: isEnabled ? activeBackgroundColor : .defaultWhite50
            ))
    }
}

/// 녹음 화면의 오른쪽 **'다음 단계(Next)'** 버튼 스타일
///
/// - **Active (활성)**: 파랑 배경 (`primaryBlue500`) / 흰색 아이콘
/// - **Disabled (비활성)**: 흰색 배경 / 연한 파랑 아이콘 (`primaryBlue50`)
struct NextStepButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(isEnabled ? .defaultWhite50 : .primaryBlue50)
            .modifier(RecordingButtonBaseModifier(
                backgroundColor: isEnabled ? .primaryBlue500 : .defaultWhite50
            ))
    }
}
