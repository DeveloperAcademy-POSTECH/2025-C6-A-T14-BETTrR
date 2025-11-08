//
//  Font.swift
//  Bettr
//
//  Created by 길정수 on 11/7/25.
//

import Foundation
import SwiftUI

extension Font {
    
    private static func sfPro(weight: Font.Weight, size: CGFloat) -> Font {
        return .system(size: size, weight: weight)
    }

    /// Semibold, 24pt
    static var subtitleSemibold24: Font {
        return .sfPro(weight: .semibold, size: 24)
    }
    
    /// Bold, 20pt
    static var iconBold20: Font {
        return .sfPro(weight: .bold, size: 20)
    }
    
    /// regular, 20pt
    static var bodyRegular20: Font {
        return .sfPro(weight: .regular, size: 20)
    }
}
