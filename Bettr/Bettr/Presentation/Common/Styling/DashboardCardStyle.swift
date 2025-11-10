//
//  DashboardCardStyle.swift
//  Bettr
//
//  Created by 길정수 on 11/10/25.
//

import SwiftUI

struct DashboardCardStyle: ViewModifier {
    let insets: EdgeInsets
    
    init(insets: EdgeInsets) {
        self.insets = insets
    }
    
    func body(content: Content) -> some View {
        content
            .padding(insets)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(.primaryBlue200)
            )
    }
}

extension View {
    
    /// **케이스 1: 4면의 padding이 모두 동일 (기본값 24)**
    ///
    /// 사용 예: `.dashboardCardStyle()` 또는 `.dashboardCardStyle(padding: 16)`
    func dashboardCardStyle(padding: CGFloat = 24) -> some View {
        let insets = EdgeInsets(top: padding,
                                leading: padding,
                                bottom: padding,
                                trailing: padding)
        return self.modifier(DashboardCardStyle(insets: insets))
    }
    
    /// **케이스 2: 상하(vertical)와 좌우(horizontal) padding을 다르게 지정**
        ///
        /// 사용 예: `.dashboardCardStyle(vertical: 16, horizontal: 24)`
    func dashboardCardStyle(vertical: CGFloat, horizontal: CGFloat) -> some View {
        let insets = EdgeInsets(top: vertical,
                                leading: horizontal,
                                bottom: vertical,
                                trailing: horizontal)
        return self.modifier(DashboardCardStyle(insets: insets))
    }
    
    /// **케이스 3: 4면의 padding을 모두 개별적으로 지정**
    ///
    /// 사용 예: `.dashboardCardStyle(top: 10, leading: 20, bottom: 30, trailing: 40)`
    func dashboardCardStyle(top: CGFloat, leading: CGFloat, bottom: CGFloat, trailing: CGFloat) -> some View {
        let insets = EdgeInsets(top: top,
                                leading: leading,
                                bottom: bottom,
                                trailing: trailing)
        return self.modifier(DashboardCardStyle(insets: insets))
    }
}
