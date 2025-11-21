//
//  TimeInterval+Extensions.swift
//  Bettr
//
//  Created by 길정수 on 11/21/25.
//

import Foundation

extension TimeInterval {
    /// MM:SS:ms (분:초:밀리초) 형식의 문자열로 변환합니다.
    func toMMSSms() -> String {
        let totalSeconds = self
        let minutes = Int(totalSeconds / 60)
        let seconds = Int(totalSeconds.truncatingRemainder(dividingBy: 60))
        let milliseconds = Int((totalSeconds.truncatingRemainder(dividingBy: 1)) * 100) // 2자리로 변경
        
        return String(format: "%02d:%02d.%02d", minutes, seconds, milliseconds)
    }
}
