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
    
    static var subtitleBold32: Font {
        return .sfPro(weight: .bold, size: 32)
    }

    static var bodyRegular28: Font {
        return .sfPro(weight: .regular, size: 28)
    }
    
    static var subtitleSemibold24: Font {
        return .sfPro(weight: .semibold, size: 24)
    }
    
    static var bodyRegular24: Font {
        return .sfPro(weight: .regular, size: 24)
    }
    
    static var iconBold20: Font {
        return .sfPro(weight: .bold, size: 20)
    }

    static var calloutRegular20: Font {
        return .sfPro(weight: .regular, size: 20)
    }


    static var labelBold16: Font {
        return .sfPro(weight: .bold, size: 16)
    }
    
    static var calloutRegular16: Font {
        return .sfPro(weight: .regular, size: 16)
    }
}
