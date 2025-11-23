//
//  FeedbackAnalysisModels.swift
//  Bettr
//
//  Created by 길정수 on 11/24/25.
//

import Foundation

/// 녹음 분석 결과의 전체 요약 정보를 담는 데이터 모델 (RecordingProcessor의 최종 산출물)
///
/// 프로세서가 계산한 정확도, 에러 카운트, 그리고 상세 단어 분석 결과를 포함
struct RecordingAnalysisResult {
    let dbDetails: [RecordingWordDetail]
    let accuracy: Double
    let missingCount: Int
    let extraCount: Int
    let replacedCount: Int
    let practiceDuration: Double
}

/// 녹음된 개별 단어에 대한 상세 분석 정보를 담는 데이터 모델
///
/// 각 단어의 차이(Diff) 상태와 문장 내 위치 정보를 포함
struct RecordingWordDetail {
    let wordDiff: WordDiff
    let originalText: String?
    let sentenceIndex: Int
    let wordIndex: Int
}
