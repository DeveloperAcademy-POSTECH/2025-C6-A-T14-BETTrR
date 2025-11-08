////
////  ButtonStyle.swift
////  Bettr
////
////  Created by 길정수 on 11/9/25.
////
//
//import SwiftUI
//
//struct GeneralButtonStyle: ButtonStyle {
//    var backgroundColor: Color
//    var foregroundColor: Color
//    var font: Font
//    var cornerRadius: CGFloat
//    
//    @Environment(\.isEnabled) private var isEnabled
//
//    func makeBody(configuration: Configuration) -> some View {
//        // 비활성화 상태일 때 색상 처리
//        let currentBackgroundColor = isEnabled ? backgroundColor :
//        let currentForegroundColor = isEnabled ? foregroundColor :
//
//        configuration.label
//            .font(font)
//            .padding(.horizontal, 16)
//            .padding(.vertical, 10)
//            .background(currentBackgroundColor)
//            .foregroundColor(currentForegroundColor)
//            .cornerRadius(cornerRadius)
//            // 눌렸을 때(isPressed) 효과
//            .opacity(configuration.isPressed ? 0.8 : 1.0)
//            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
//            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
//    }
//}
//
//// --- 2. 툴바 버튼용 스타일 (아이콘 색과 폰트만 제어) ---
//
//struct ToolbarButtonModifier: ViewModifier {
//    var tintColor: Color
//    var font: Font
//    
//    func body(content: Content) -> some View {
//        content
//            .font(font)
//            // .buttonStyle(.bordered)는 옅은 회색 배경을 만들어줍니다.
//            // (이미지와 가장 유사한 스타일)
//            .buttonStyle(.bordered)
//            // .tint()가 아이콘 색상을 결정합니다.
//            .tint(tintColor)
//            // .buttonBorderShape(.circle)이 배경을 원으로 만듭니다.
//            .buttonBorderShape(.circle)
//    }
//}
//
//// --- 3. 사용하기 편하도록 '프리셋' 정의 ---
//
//// ButtonStyle에 대한 확장
//extension ButtonStyle where Self == GeneralButtonStyle {
//    
//    /// 파란색 배경의 표준 '활성화' 버튼 프리셋
//    static var standardActive: GeneralButtonStyle {
//        GeneralButtonStyle(
//            backgroundColor: .blue,
//            foregroundColor: .white,
//            font: .headline,
//            cornerRadius: 10
//        )
//    }
//    
//    /// 회색 배경의 '일반' 버튼 프리셋
//    static var standardSecondary: GeneralButtonStyle {
//        GeneralButtonStyle(
//            backgroundColor: .gray.opacity(0.15),
//            foregroundColor: .black,
//            font: .subheadline,
//            cornerRadius: 8
//        )
//    }
//}
//
//// View에 대한 확장 (툴바용)
//extension View {
//    
//    /// 툴바 '활성화' 프리셋 (중간 이미지: 검은색 아이콘)
//    func toolbarActivated() -> some View {
//        self.modifier(ToolbarButtonModifier(
//            tintColor: .black,
//            font: .headline.weight(.medium)
//        ))
//    }
//    
//    /// 툴바 '강조' 프리셋 (아래 이미지: 파란색 아이콘)
//    func toolbarEmphasized() -> some View {
//        self.modifier(ToolbarButtonModifier(
//            tintColor: Color.blue.opacity(0.8),
//            font: .headline.weight(.medium)
//        ))
//    }
//}
