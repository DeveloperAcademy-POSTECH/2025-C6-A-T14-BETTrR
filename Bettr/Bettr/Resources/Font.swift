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

    /// semibold, 24pt
    static var subtitleSemibold24: Font {
        return .sfPro(weight: .semibold, size: 24)
    }
    
    /// regular, 28pt
    static var bodyRegular28: Font {
        return .sfPro(weight: .regular, size: 28)
    }

    /// regular, 16pt
    static var calloutRegular16: Font {
        return .sfPro(weight: .regular, size: 16)
    }
    
    /// bold, 20pt
    static var iconBold20: Font {
        return .sfPro(weight: .bold, size: 20)
    }
}
