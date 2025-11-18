//
//  Route.swift
//  Bettr
//
//  Created by 길정수 on 10/30/25.
//

import SwiftUI

enum Route: Hashable {
    case home
    case scriptConfirm(initialText: String?, initialTitle: String?)
    case scriptDashboard(scriptId: Int64)
    case memorization(scriptId: Int64, scriptTitle: String, currentFeedbackCount: Int)
    case historicalFeedback(summary: FeedbackSummary, scriptTitle: String, feedbackNumber: Int)
    case allFeedback(feedbacks: [FeedbackSummary], scriptTitle: String, feedbackNumber: Int)
}

enum ModalRoute: Hashable {
    case feedbackResult(
        diffs: [WordDiff],
        practiceDuration: Double,
        sentences: [String],
        scriptTitle: String,
        currentFeedbackCount: Int
    )
}
