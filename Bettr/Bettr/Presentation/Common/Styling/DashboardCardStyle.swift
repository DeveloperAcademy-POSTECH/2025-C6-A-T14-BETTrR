//
//  DashboardCardStyle.swift
//  Bettr
//
//  Created by 길정수 on 11/10/25.
//

import SwiftUI

struct DashboardCardStyle: ViewModifier {
    let padding: CGFloat
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(.primaryBlue200)
            )
    }
}

extension View {
    func dashboardCardStyle(padding: CGFloat = 24) -> some View {
        self.modifier(DashboardCardStyle(padding: padding))
    }
}
