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
    
    @ScaledMetric var top: CGFloat
    @ScaledMetric var leading: CGFloat
    @ScaledMetric var bottom: CGFloat
    @ScaledMetric var trailing: CGFloat
    
    let style: DashboardCardStyleType
    
    init(top: CGFloat, leading: CGFloat, bottom: CGFloat, trailing: CGFloat, relativeTo textStyle: Font.TextStyle, style: DashboardCardStyleType) {
        _top = ScaledMetric(wrappedValue: top, relativeTo: textStyle)
        _leading = ScaledMetric(wrappedValue: leading, relativeTo: textStyle)
        _bottom = ScaledMetric(wrappedValue: bottom, relativeTo: textStyle)
        _trailing = ScaledMetric(wrappedValue: trailing, relativeTo: textStyle)
        self.style = style
    }
    
    init(padding: CGFloat, relativeTo textStyle: Font.TextStyle, style: DashboardCardStyleType) {
        self.init(top: padding,
                  leading: padding,
                  bottom: padding,
                  trailing: padding,
                  relativeTo: textStyle,
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
    func dashboardCardStyle(padding: CGFloat = 24, relativeTo textStyle: Font.TextStyle = .body, style: DashboardCardStyleType) -> some View {
        self.modifier(DashboardCardStyle(padding: padding,
                                         relativeTo: textStyle,
                                         style: style))
    }
    
    func dashboardCardStyle(top: CGFloat, leading: CGFloat, bottom: CGFloat, trailing: CGFloat, relativeTo textStyle: Font.TextStyle, style: DashboardCardStyleType) -> some View {
        self.modifier(DashboardCardStyle(top: top,
                                         leading: leading,
                                         bottom: bottom,
                                         trailing: trailing,
                                         relativeTo: textStyle,
                                         style: style))
    }
}
