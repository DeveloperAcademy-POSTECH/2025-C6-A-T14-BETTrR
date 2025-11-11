//
//  Font.swift
//  Bettr
//
//  Created by 길정수 on 11/7/25.
//

import Foundation
import SwiftUI

extension Font {
    
//    private static func sfPro(weight: Font.Weight, size: CGFloat) -> Font {
//        return .system(size: size, weight: weight)
//    }
//    
//    static var labelMedium64: Font {
//        return .sfPro(weight: .medium, size: 64)
//    }
//
//    static var subtitleBold32: Font {
//        return .sfPro(weight: .bold, size: 32)
//    }
//
//    static var bodyRegular28: Font {
//        return .sfPro(weight: .regular, size: 28)
//    }
//    
//    static var subbodyBold24: Font {
//        return .sfPro(weight: .bold, size: 24)
//    }
//    
//    static var subtitleSemibold24: Font {
//        return .sfPro(weight: .semibold, size: 24)
//    }
//    
//    static var bodyRegular24: Font {
//        return .sfPro(weight: .regular, size: 24)
//    }
//    
//    static var iconBold20: Font {
//        return .sfPro(weight: .bold, size: 20)
//    }
//
//    static var subbodyRegular20: Font {
//        return .sfPro(weight: .regular, size: 20)
//    }
//
//    static var calloutRegular20: Font {
//        return .sfPro(weight: .regular, size: 20)
//    }
//
//    static var labelBold16: Font {
//        return .sfPro(weight: .bold, size: 16)
//    }
//    
//    static var calloutRegular16: Font {
//        return .sfPro(weight: .regular, size: 16)
//    }
//    
//    static var labelRegular14: Font {
//        return .sfPro(weight: .regular, size: 14)
//    }
//    
//    static var footerRegular11: Font {
//        return .sfPro(weight: .regular, size: 11)
//    }
    
    private static func sfPro(style: Font.TextStyle, weight: Font.Weight) -> Font {
    return .system(style, weight: weight)
    }
    
    static var labelMedium64: Font {
        return .system(size: 64, weight: .medium)
    }
    
    static var subtitleBold32: Font {
        return .sfPro(style: .largeTitle, weight: .bold)
    }
    
    static var bodyRegular28: Font {
        return .sfPro(style: .title, weight: .regular)
    }
    
    static var subbodyBold24: Font {
        return .sfPro(style: .title2, weight: .bold)
    }
    
    static var subtitleSemibold24: Font {
        return .sfPro(style: .title2, weight: .semibold)
    }
    
    static var bodyRegular24: Font {
        return .sfPro(style: .title3, weight: .regular)
    }
    
    static var iconBold20: Font {
        return .sfPro(style: .title3, weight: .bold)
    }
    
    static var subbodyRegular20: Font {
        return .sfPro(style: .title3, weight: .regular)
    }
    
    static var calloutRegular20: Font {
        return .sfPro(style: .title3, weight: .regular)
    }
    
    static var labelBold16: Font {
        return .sfPro(style: .callout, weight: .bold)
    }
    
    static var calloutRegular16: Font {
        return .sfPro(style: .callout, weight: .regular)
    }
    
    static var labelRegular14: Font {
        return .sfPro(style: .footnote, weight: .regular)
    }
    
    static var footerRegular11: Font {
        return .sfPro(style: .caption2, weight: .regular)
    }
}


