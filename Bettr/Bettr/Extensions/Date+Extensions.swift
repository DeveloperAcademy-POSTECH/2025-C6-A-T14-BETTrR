//
//  DateFormatter.swift
//  Bettr
//
//  Created by 길정수 on 11/6/25.
//

import Foundation

extension Date {
    /// "yy/MM/dd" (예: "25/11/06") 포맷의 문자열로 변환합니다.
    func asAppDateString() -> String {
        return Self.appDateFormatter.string(from: self)
    }
    
    // 앱 내에서 공통으로 사용할 날짜 포맷
    private static var appDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yy/MM/dd"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()
}
