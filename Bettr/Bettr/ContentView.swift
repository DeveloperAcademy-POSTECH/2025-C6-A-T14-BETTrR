//
//  ContentView.swift
//  Bettr
//
//  Created by 서세린 on 10/30/25.
//

import SwiftUI

struct ContentView: View {
    
    @Environment(DatabaseContainer.self) private var container
    @State private var router = NavigationRouter()
    @State private var homeModel: HomeListModel
    @Environment(AudioPlaybackService.self) private var audioService
    
    init(scriptService: any ScriptManagementServiceProtocol) {
        _homeModel = State(initialValue: HomeListModel(scriptService: scriptService))
    }

    var body: some View {
        
        @Bindable var router = router
        
        NavigationStack(path: $router.path) {
            HomeView(model: homeModel)
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .home:
                        HomeView(model: homeModel)
                        
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
        .environment(router)
    }
}

#Preview {
    AsyncPreview(operation: {
        try await DatabaseContainer.getForPreview(withMockData: true)
    }) { container in
        ContentView(scriptService: container.scriptManagementService)
            .environment(container)
            .environment(AudioPlaybackService())
    }
}
