//
//  FeedbackStatisticsLayoutMode.swift
//  Bettr
//
//  Created by 길정수 on 11/23/25.
//

import SwiftUI

enum FeedbackStatisticsLayoutMode {
    case full
    case compact
    
    /// 내부 컴포넌트 간 간격
    var spacing: CGFloat {
        switch self {
        case .full: return 48
        case .compact: return 24
        }
    }
}
