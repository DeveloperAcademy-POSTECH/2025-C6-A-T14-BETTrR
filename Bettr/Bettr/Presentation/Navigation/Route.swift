//
//  Route.swift
//  Bettr
//
//  Created by 길정수 on 10/30/25.
//

import SwiftUI

enum Route: Hashable {
    case home
    case scriptConfirm(initialText: String?)
    case scriptDashboard(scriptId: Int64)
    case memorization(scriptId: Int64)
}

enum ModalRoute: Hashable {
    case feedbackResult(result: FeedbackResultModel, sentences: [String])
}
