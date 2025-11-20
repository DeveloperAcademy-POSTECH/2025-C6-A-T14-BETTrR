//
//  FeedbackHistoryModel.swift
//  Bettr
//
//  Created by 길정수 on 11/20/25.
//

import Foundation

/// 대시보드 뷰에서 필요한 스크립트 데이터만 담는 모델
struct FeedbackHistoryModel: Hashable {
    var title: String
    
    // FeedbackSummary는 최신순으로 정렬
    let allFeedbackSummaries: [FeedbackSummary]
    let recentFeedbackSummaries: [FeedbackSummary]
    let frequentlyWrongWords: [WrongWordCount]
    let feedbackCount: Int
}

/// "자주 틀린 단어" 데이터를 담기 위한 모델
struct WrongWordCount: Hashable, Identifiable {
    let word: String
    let count: Int
    
    var id: String { word }
}
