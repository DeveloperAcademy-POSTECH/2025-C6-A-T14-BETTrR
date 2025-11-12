//
//  DashboardCardStyle.swift
//  Bettr
//
//  Created by 길정수 on 11/10/25.
//
import SwiftUI

struct BorderCardStyle: ViewModifier {
    var vertical: CGFloat
    var leading: CGFloat
    var trailing: CGFloat
    
    func body(content: Content) -> some View {
        content
            .padding(.vertical, vertical)
            .padding(.leading, leading)
            .padding(.trailing, trailing)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(.primaryBlue200)
            )
    }
}

struct FilledCardStyle: ViewModifier {
    var top: CGFloat
    var bottom: CGFloat
    var leading: CGFloat
    var trailing: CGFloat
    
    func body(content: Content) -> some View {
        content
            .padding(.top, top)
            .padding(.bottom, bottom)
            .padding(.leading, leading)
            .padding(.trailing, trailing)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.primaryBlue50)
            )
    }
}

extension View {
    func cardBorder(padding: CGFloat = 24) -> some View {
        self.modifier(BorderCardStyle(vertical: padding, leading: padding, trailing: padding))
    }
    
    func cardBorder(padding: CGFloat = 24, trailing: CGFloat = 16) -> some View {
        self.modifier(BorderCardStyle(vertical: padding, leading: padding, trailing: trailing))
    }
    
    func cardFilled(padding: CGFloat = 36) -> some View {
        self.modifier(
            FilledCardStyle(top: padding,
                            bottom: padding,
                            leading: padding,
                            trailing: padding)
        )
    }
    
    func cardFilled(
        top: CGFloat = 0,
        bottom: CGFloat = 31,
        leading: CGFloat = 22,
        trailing: CGFloat = 0
    ) -> some View {
        self.modifier(
            FilledCardStyle(top: top,
                            bottom: bottom,
                            leading: leading,
                            trailing: trailing)
        )
    }
}


// TODO: - 추후 삭제


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
