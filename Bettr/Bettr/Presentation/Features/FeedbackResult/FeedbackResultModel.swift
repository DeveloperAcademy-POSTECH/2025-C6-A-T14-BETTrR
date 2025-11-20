//
//  FeedbackResultModel.swift
//  Bettr
//
//  Created by 길정수 on 11/12/25.
//

import Foundation

struct FeedbackResultModel {
    // 뷰에서 사용할 데이터 타입
    typealias SentenceDiffData = (original: String, diffs: [WordDiff])
    typealias FilteredSentenceDiff = (index: Int, data: SentenceDiffData)
    
    // MARK: - Properties
    
    let scriptTitle: String
    let feedbackNumber: Int
    let accuracy: Double
    let totalRecordingTime: TimeInterval
    let missingCount: Int
    let extraCount: Int
    let replacedCount: Int
    
    /// (index: 원본 인덱스, data: (original: 원본 문장, diffs: [WordDiff]))
    let filteredSentenceDiffs: [FilteredSentenceDiff]
}
