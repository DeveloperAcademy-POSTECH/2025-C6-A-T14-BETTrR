//
//  ToolbarButtonModifier.swift
//  Bettr
//
//  Created by 길정수 on 11/9/25.
//

import SwiftUI

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
    
    /// 툴바 활성화
    func toolbarEnabled() -> some View {
        self.modifier(ToolbarButtonModifier(
            foregroundColor: .secondaryBlue700,
            fontWeight: .regular
        ))
    }
    
    /// 툴바 비활성화
    func toolbarDisabled() -> some View {
        self.modifier(ToolbarButtonModifier(
            foregroundColor: .primaryBlue200,
            fontWeight: .regular
        ))
    }
    
    /// 툴바 강조
    func toolbarEmphasized() -> some View {
        self.modifier(ToolbarButtonModifier(
            foregroundColor: .primaryBlue500,
            fontWeight: .bold
        ))
    }
    
    /// 상태에 따라 활성화 또는 강조
    @ViewBuilder
    func toolbarButtonStyle(emphasized isActive: Bool) -> some View {
        if isActive {
            self.toolbarEmphasized()
        } else {
            self.toolbarEnabled()
        }
    }
    
    /// 상태에 따라 활성화 또는 비활성화
    @ViewBuilder
    func toolbarButtonStyle(enabled isActive: Bool) -> some View {
        if isActive {
            self.toolbarEnabled()
        } else {
            self.toolbarDisabled()
        }
    }
}
