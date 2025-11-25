//
//  ScoreTrendSection.swift
//  Bettr
//
//  Created by 길정수 on 11/23/25.
//

import SwiftUI

struct ScoreTrendSection: View {
    let summaries: [FeedbackSummary]
    
    var body: some View {
        TitledSection.standard(title: "종합 점수 추이") {
            ScoreTrendChart(allFeedbackSummaries: summaries)
        }
    }
}
