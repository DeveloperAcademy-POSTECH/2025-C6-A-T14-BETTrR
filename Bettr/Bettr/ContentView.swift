//
//  ContentView.swift
//  Bettr
//
//  Created by 서세린 on 10/30/25.
//

import SwiftUI

struct ContentView: View {
    @State private var router = NavigationRouter()
    @State private var audioService = AudioPlaybackService()
    
    @Environment(DatabaseContainer.self) private var container
    
    var body: some View {
        NavigationStack(path: $router.path) {
            HomeView()
                .navigationTitle("Bettr")
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .home:
                        HomeView()
                    case .scriptConfirm(let initialText, let initialTitle):
                        ScriptConfirmView(initialText: initialText, initialTitle: initialTitle)
                    case .scriptDashboard(let scriptId):
                        let viewModel = ScriptDashboardViewModel(
                            scriptId: scriptId,
                            scriptService: container.scriptManagementService
                        )
                        ScriptDashboardView(viewModel: viewModel)
                    case .memorization(let scriptId, let scriptTitle, let currentFeedbackCount):
                        let viewModel = MemorizationViewModel(
                            scriptId: scriptId,
                            scriptTitle: scriptTitle,
                            currentFeedbackCount: currentFeedbackCount,
                            scriptService: container.scriptManagementService,
                            audioService: audioService,
                            wordExtractionService: container.wordExtractionService
                        )
                        MemorizationView(viewModel: viewModel)
                    case .historicalFeedback(let summary, let scriptTitle, let feedbackNumber):
                        let viewModel = HistoricalFeedbackViewModel(
                            summary: summary,
                            scriptTitle: scriptTitle,
                            feedbackNumber: feedbackNumber,
                            scriptManagementService: container.scriptManagementService
                        )
                        HistoricalFeedbackView(viewModel: viewModel)
                    case .allFeedback(let feedbacks, let scriptTitle, let feedbackNumber):
                        AllFeedbackView(feedbacks: feedbacks, scriptTitle: scriptTitle,
                                        feedbackNumber: feedbackNumber,)
                    }
                }
        }
        .environment(router)
        .environment(audioService)
    }
}

#Preview {
    ContentView()
        .environment(DatabaseContainer.getForPreview())
}
