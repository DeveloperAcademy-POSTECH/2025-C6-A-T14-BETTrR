//
//  FeedbackDetailParams.swift
//  Bettr
//
//  Created by 길정수 on 11/23/25.
//


import Foundation

/// 피드백 상세 정보(단어별 분석 결과)를 DB에 저장하기 위해 전달하는 데이터 모델
struct FeedbackDetailParams {
    let wordDiff: WordDiff
    let originalText: String?
    let sentenceIndex: Int
    let wordIndex: Int
}