//
//  WordDiff.swift
//  Bettr
//
//  Created by 길정수 on 11/11/25.
//

import Foundation

// MARK: - 분석 결과 상세 모델 (WordDiff)
/// 단어별 분석 상태를 나타내는 열거형
enum WordDiff: Hashable, Sendable {
    // 원본과 일치하는 단어
    case matched(word: String)
    // 원본에 있지만 발화에서 누락된 단어
    case missing(expected: String)
    // 원본에 없지만 발화에 추가된 단어
    case extra(actual: String)
    // 원본의 단어가 다른 단어로 대체된 경우
    case replaced(expected: String, actual: String)

    // DB 저장 시 사용될 타입 식별자
    var dbTypeValue: String {
        switch self {
        case .matched: return "matched"
        case .missing: return "missing"
        case .extra: return "extra"
        case .replaced: return "replaced"
        }
    }
}
