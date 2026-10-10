import SwiftUI

@MainActor
struct ContentView: View {
    private let composition: AppComposition
    @State private var homeModel: HomeListModel
    @State private var router = NavigationRouter()

    init(composition: AppComposition) {
        self.composition = composition
        _homeModel = State(initialValue: composition.makeHomeListModel())
    }

    var body: some View {
        @Bindable var router = router

        NavigationStack(path: $router.path) {
            composition.makeHomeView(model: homeModel)
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .home:
                        composition.makeHomeView(model: homeModel)
                    case .scriptConfirm(let text, let title):
                        composition.makeScriptConfirmView(initialText: text, initialTitle: title)
                    case .memorization(let scriptId, let title):
                        composition.makeMemorizationView(scriptId: scriptId, scriptTitle: title)
                    }
                }
        }
        .environment(router)
    }
}

#Preview {
    AsyncPreview(operation: { try await PreviewComposition.withDemoData() }) { composition in
        ContentView(composition: composition)
    }
}
