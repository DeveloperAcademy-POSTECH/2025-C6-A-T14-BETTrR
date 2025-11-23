//
//  SummarSaveParams.swift
//  Bettr
//
//  Created by 길정수 on 11/23/25.
//

import Foundation

/// 피드백 요약 정보(전체 통계)를 DB에 저장하기 위해 전달하는 데이터 모델
struct SummarySaveParams {
    let dbDetails: [FeedbackDetailParams]
    let accuracy: Double
    let missingCount: Int
    let extraCount: Int
    let replacedCount: Int
    let practiceDuration: Double
}
