//
//  Formatters.swift
//  Bettr
//
//  Created by 길정수 on 11/6/25.
//

import Foundation

extension Double {
    /// 연습 시간(초)을 "mm:ss.SS" 포맷의 문자열로 변환합니다.
    func asPracticeDurationString() -> String {
        let totalSeconds = self
        
        let minutes = Int(totalSeconds) / 60
        let seconds = Int(totalSeconds) % 60
        
        // 밀리초 계산
        let milliseconds = Int((totalSeconds - floor(totalSeconds)) * 100)
        
        // "dd:dd.dd" (mm:ss.SS) 포맷
        return String(format: "%02d:%02d.%02d", minutes, seconds, milliseconds)
    }
}
