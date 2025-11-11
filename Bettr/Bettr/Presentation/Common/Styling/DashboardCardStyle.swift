//
//  DashboardCardStyle.swift
//  Bettr
//
//  Created by 길정수 on 11/10/25.
//
import SwiftUI

enum DashboardCardStyleType {
    case fill(Color)
    case border(Color, lineWidth: CGFloat = 1)
}

struct DashboardCardStyle: ViewModifier {
    
    var top: CGFloat
    var leading: CGFloat
    var bottom: CGFloat
    var trailing: CGFloat
    
    let style: DashboardCardStyleType
    
    init(top: CGFloat, leading: CGFloat, bottom: CGFloat, trailing: CGFloat, style: DashboardCardStyleType) {
        self.top = top
        self.leading = leading
        self.bottom = bottom
        self.trailing = trailing
        self.style = style
    }
    
    init(padding: CGFloat, style: DashboardCardStyleType) {
        self.init(top: padding,
                  leading: padding,
                  bottom: padding,
                  trailing: padding,
                  style: style)
    }
    
    func body(content: Content) -> some View {
        content
            .padding(EdgeInsets(top: top,
                                leading: leading,
                                bottom: bottom,
                                trailing: trailing))
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .dashboardCardBackground(style: style)
            )
    }
}

private extension RoundedRectangle {
    @ViewBuilder
    func dashboardCardBackground(style: DashboardCardStyleType) -> some View {
        switch style {
        case .fill(let color):
            self.fill(color)
        case .border(let color, let lineWidth):
            self.strokeBorder(color, lineWidth: lineWidth)
        }
    }
}

extension View {
    func dashboardCardStyle(padding: CGFloat = 24, style: DashboardCardStyleType) -> some View {
        self.modifier(DashboardCardStyle(padding: padding,
                                         style: style))
    }
    
    func dashboardCardStyle(top: CGFloat, leading: CGFloat, bottom: CGFloat, trailing: CGFloat, style: DashboardCardStyleType) -> some View {
        self.modifier(DashboardCardStyle(top: top,
                                         leading: leading,
                                         bottom: bottom,
                                         trailing: trailing,
                                         style: style))
    }
}
