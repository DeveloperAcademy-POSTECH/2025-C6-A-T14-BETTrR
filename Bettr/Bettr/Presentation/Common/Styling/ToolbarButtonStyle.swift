//
//  ToolbarButtonStyle.swift
//  Bettr
//
//  Created by 길정수 on 11/9/25.
//

import SwiftUI

enum ToolbarButtonState {
    case normal
    case emphasized
    case disabled
}

struct ToolbarButtonModifier: ViewModifier {
    var foregroundColor: Color
    var fontWeight: Font.Weight
    
    func body(content: Content) -> some View {
        content
            .fontWeight(fontWeight)
            .foregroundStyle(foregroundColor)
    }
}

extension View {
    /// 버튼의 상태(기본, 강조, 비활성)를 Enum으로 결정합니다.
    @ViewBuilder
    func toolbarButtonStyle(_ state: ToolbarButtonState) -> some View {
        switch state {
        case .normal:
            self.toolbarNormal()
        case .emphasized:
            self.toolbarEmphasized()
        case .disabled:
            self.toolbarDisabled()
        }
    }
        
    func toolbarNormal() -> some View {
        self.modifier(ToolbarButtonModifier(
            foregroundColor: .secondaryBlue700,
            fontWeight: .regular
        ))
    }
    
    func toolbarDisabled() -> some View {
        self.modifier(ToolbarButtonModifier(
            foregroundColor: .primaryBlue200,
            fontWeight: .regular
        ))
    }
    
    func toolbarEmphasized() -> some View {
        self.modifier(ToolbarButtonModifier(
            foregroundColor: .primaryBlue500,
            fontWeight: .bold
        ))
    }
}
