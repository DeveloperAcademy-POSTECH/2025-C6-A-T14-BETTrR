//
//  FeedbackChartDataPoint.swift
//  Bettr
//
//  Created by 길정수 on 11/21/25.
//

import Foundation

struct FeedbackChartDataPoint: Identifiable {
    let id: Int
    let session: Int
    let score: Int
    
    init(session: Int, score: Int) {
        self.id = session
        self.session = session
        self.score = score
    }
}
