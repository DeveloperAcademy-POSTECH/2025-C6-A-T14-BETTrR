//
//  AllFeedbackViewModel.swift
//  Bettr
//
//  Created by 길정수 on 11/13/25.
//

import Foundation

@Observable
class AllFeedbackViewModel {
    
    // MARK: - 1. View's Data (뷰가 표시할 최종 데이터)
    
    /// 계산의 기준이 될 원본 전체 리스트 (최신순 정렬)
    let allSortedFeedbacks: [FeedbackSummary]
    
    /// 1시간 이내 생성된 피드백 (최신순)
    let recentFeedbacks: [FeedbackSummary]
    
    /// 1시간 이전에 생성된 피드백 (최신순)
    let previousFeedbacks: [FeedbackSummary]
    
    /// 네비게이션 시 하위 뷰(FeedbackSummaryCard)에 전달할 메타데이터
    let scriptTitle: String
    let allFeedbackCount: Int
    
    // MARK: - 2. Init (로직 수행)
    
    init(
        allFeedbacks: [FeedbackSummary],
        scriptTitle: String,
    ) {
        self.allSortedFeedbacks = allFeedbacks
        self.scriptTitle = scriptTitle
        self.allFeedbackCount = allFeedbacks.count
        
        let oneHourAgo = Date().addingTimeInterval(-3600) // 1시간
        
        let feedbackGroups = Dictionary(grouping: allFeedbacks) {
            $0.createdAt > oneHourAgo
        }
        
        // 1시간 이내 (true 그룹), 최신순 정렬
        self.recentFeedbacks = (feedbackGroups[true] ?? [])
            .sorted { $0.createdAt > $1.createdAt }
        
        // 1시간 이전 (false 그룹), 최신순 정렬
        self.previousFeedbacks = (feedbackGroups[false] ?? [])
            .sorted { $0.createdAt > $1.createdAt }
    }
}
