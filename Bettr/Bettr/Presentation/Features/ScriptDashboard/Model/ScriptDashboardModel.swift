//
//  ScriptDashboardModel.swift
//  Bettr
//
//  Created by 길정수 on 11/4/25.
//

import Foundation

/// 대시보드 뷰에서 필요한 스크립트 데이터만 담는 모델
struct ScriptDashboardModel: Hashable {
    let title: String
    let sentences: [ScriptDashboardSentenceModel]
    let feedbacks: [FeedbackSummary]
}

/// 대시보드 뷰에서 사용할 문장 데이터 모델
struct ScriptDashboardSentenceModel: Hashable, Identifiable {
    let id: Int64?
    let orderIndex: Int
    let englishText: String
}
