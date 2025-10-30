//
//  Route.swift
//  Bettr
//
//  Created by 길정수 on 10/30/25.
//

import SwiftUI

enum Route: Hashable {
    case memorization(scriptData: ScriptData)
    case scriptInput
}

enum ModalRoute: Hashable {
    case feedbackResult(result: FeedbackResultModel, sentences: [String])
}
