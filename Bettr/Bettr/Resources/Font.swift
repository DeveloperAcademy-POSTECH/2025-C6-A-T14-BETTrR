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
}
