//
//  ContentView.swift
//  Bettr
//
//  Created by 서세린 on 10/30/25.
//

import SwiftUI

struct ContentView: View {
    
    @Environment(DatabaseContainer.self) private var container
    @Environment(NavigationRouter.self) private var router
    @Environment(AudioPlaybackService.self) private var audioService
    
    var body: some View {
        
        @Bindable var router = router
        
        NavigationStack(path: $router.path) {
            HomeView()
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .home:
                        HomeView()
                        
                    case .scriptConfirm(let initialText, let initialTitle):
                        ScriptConfirmView(initialText: initialText, initialTitle: initialTitle)

                    case .memorization(let scriptId, let scriptTitle):
                        let mainViewModel = MemorizationViewModel(
                            scriptId: scriptId,
                            scriptTitle: scriptTitle,
                            scriptService: container.scriptManagementService,
                            audioService: audioService,
                        )
                        
                        let wordViewModel = WordListViewModel(
                            scriptId: scriptId,
                            wordExtractionService: container.wordExtractionService
                        )
                        
                        MemorizationView(
                            viewModel: mainViewModel,
                            wordListViewModel: wordViewModel
                        )
                    }
                }
        }
    }
}

#Preview {
    AsyncPreview(operation: {
        try await DatabaseContainer.getForPreview(withMockData: true)
    }) { container in
        ContentView()
            .environment(container)
            .environment(NavigationRouter())
            .environment(AudioPlaybackService())
    }
}
