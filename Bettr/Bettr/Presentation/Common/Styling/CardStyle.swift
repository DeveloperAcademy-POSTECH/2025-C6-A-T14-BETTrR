//
//  DashboardCardStyle.swift
//  Bettr
//
//  Created by 길정수 on 11/10/25.
//
import SwiftUI

/// 테두리가 있는 카드 스타일
/// Radius 20, 테두리색 primaryBlue200
struct BorderedCardStyle: ViewModifier {
    var top: CGFloat, bottom: CGFloat, leading: CGFloat, trailing: CGFloat
    var cornerRadius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .padding(EdgeInsets(top: top, leading: leading, bottom: bottom, trailing: trailing))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(.primaryBlue200, lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

/// 배경색이 있는 카드 스타일
/// Radius 20, 배경색 primaryBlue50
struct FilledCardStyle: ViewModifier {
    var top: CGFloat, bottom: CGFloat, leading: CGFloat, trailing: CGFloat
    var cornerRadius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .padding(EdgeInsets(top: top, leading: leading, bottom: bottom, trailing: trailing))
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.primaryBlue50)
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

/// 배경색과 테두리가 모두 있는 카드 스타일
/// Radius 20, 배경색 primaryBlue50, 테두리색 primaryBlue200
struct BorderedFilledCardStyle: ViewModifier {
    var top: CGFloat, bottom: CGFloat, leading: CGFloat, trailing: CGFloat
    var cornerRadius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .padding(EdgeInsets(top: top, leading: leading, bottom: bottom, trailing: trailing))
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.primaryBlue50)
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(.primaryBlue200, lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

extension View {
    /// 4면의 패딩이 모두 같은 테두리가 있는 카드 스타일
    func cardBordered(padding: CGFloat, cornerRadius: CGFloat = 20) -> some View {
        self.modifier(BorderedCardStyle(
            top: padding, bottom: padding, leading: padding, trailing: padding,            cornerRadius: cornerRadius
        ))
    }
    
    /// trailing의 패딩 값만 다른 테두리가 있는 카드 스타일
    /// - 기본값: padding = 24, trailing = 16
    func cardBordered(padding: CGFloat = 24, trailing: CGFloat = 16, cornerRadius: CGFloat = 20) -> some View {
        self.modifier(BorderedCardStyle(
            top: padding, bottom: padding, leading: padding, trailing: trailing,
            cornerRadius: cornerRadius
        ))
    }
    
    /// 4면의 패딩이 모두 같은 배경색이 있는 카드 스타일
    func cardFilled(padding: CGFloat, cornerRadius: CGFloat = 20) -> some View {
        self.modifier(FilledCardStyle(
            top: padding, bottom: padding, leading: padding, trailing: padding,
            cornerRadius: cornerRadius
        ))
    }
    
    /// 4면의 패딩값을 모두 지정할 수 있는 배경색이 있는 카드 스타일
    /// - 기본값: top = 0,  bottom = 31, leading = 22, trailing = 0
    func cardFilled(top: CGFloat = 0, bottom: CGFloat = 31, leading: CGFloat = 22, trailing: CGFloat = 0, cornerRadius: CGFloat = 10) -> some View {
        self.modifier(FilledCardStyle(
            top: top, bottom: bottom, leading: leading, trailing: trailing,
            cornerRadius: cornerRadius
        ))
    }
    
    /// 4면의 패딩이 모두 같은 배경색과 테두리가 있는 카드 스타일
    func cardBorderedFilled(padding: CGFloat, cornerRadius: CGFloat = 20) -> some View {
        self.modifier(BorderedFilledCardStyle(
            top: padding, bottom: padding, leading: padding, trailing: padding,
            cornerRadius: cornerRadius
        ))
    }
}
