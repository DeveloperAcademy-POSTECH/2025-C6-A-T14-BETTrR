//
//  FeedbackResultModel.swift
//  Bettr
//
//  Created by 길정수 on 10/30/25.
//

import Foundation

// MARK: - 분석 결과 상세 모델 (WordDiff)
/// 단어별 분석 상태를 나타내는 열거형
enum WordDiff: Hashable {
    /// 원본과 일치하는 단어
    case matched(word: String)
    /// 원본에 있지만 발화에서 누락된 단어
    case missing(expected: String)
    /// 원본에 없지만 발화에 추가된 단어
    case extra(actual: String)
    /// 원본의 단어가 다른 단어로 대체된 경우
    case replaced(expected: String, actual: String)
}

// MARK: - 분석 결과 모델
struct FeedbackResultModel: Hashable {
    /// 전체 스크립트에 대한 WordDiff 배열 (순서 보장)
    let diffs: [WordDiff]
    
    /// 전체 정확도
    let accuracy: Double
    
    /// 원본 스크립트의 총 단어 수
    let totalOriginalWords: Int
    
    /// 총 녹음 시간
    var totalRecordingTime: TimeInterval = 0.0
}
