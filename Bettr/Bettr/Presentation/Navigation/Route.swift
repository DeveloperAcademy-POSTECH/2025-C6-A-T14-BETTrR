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
    case memorization(scriptId: Int64, scriptTitle: String)
}

enum ModalRoute: Hashable {
    case recording(sentences: [String], scriptTitle: String, currentFeedbackCount: Int)
    case feedbackResult(summaryId: Int64, fromRecording: Bool)
}
