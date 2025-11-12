//
//  DashboardCardStyle.swift
//  Bettr
//
//  Created by 길정수 on 11/10/25.
//
import SwiftUI

struct BorderedCardStyle: ViewModifier {
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

struct BorderedFilledCardStyle: ViewModifier {
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
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(.primaryBlue200)
                    )
            )
    }
}

extension View {
    func cardBordered(padding: CGFloat) -> some View {
        self.modifier(BorderedCardStyle(top: padding, bottom: padding, leading: padding, trailing: padding))
    }
    
    func cardBordered(padding: CGFloat = 24, trailing: CGFloat = 16) -> some View {
        self.modifier(BorderedCardStyle(top: padding, bottom: padding, leading: padding, trailing: trailing))
    }
    
    func cardFilled(padding: CGFloat) -> some View {
        self.modifier(
            FilledCardStyle(top: padding, bottom: padding, leading: padding, trailing: padding)
        )
    }
    
    func cardFilled(top: CGFloat = 0, bottom: CGFloat = 31, leading: CGFloat = 22, trailing: CGFloat = 0) -> some View {
        self.modifier(
            FilledCardStyle(top: top, bottom: bottom, leading: leading, trailing: trailing)
        )
    }
    
    func cardBorderedFilled(padding: CGFloat) -> some View {
        self.modifier(BorderedFilledCardStyle(top: padding, bottom: padding, leading: padding, trailing: padding))
    }
}
