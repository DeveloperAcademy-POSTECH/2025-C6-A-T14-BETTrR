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
#if DEBUG
        .overlay(alignment: .bottomTrailing) {
            if AppLaunchContext.usesIsolatedDependencies,
               ProcessInfo.processInfo.arguments.contains("--script-confirm-ui-test"),
               router.path.isEmpty {
                Button("Open script confirm fixture") {
                    router.push(Route.scriptConfirm(initialText: "Hello world.", initialTitle: "UI regression"))
                }
                .accessibilityIdentifier("ui-test.open-script-confirm")
            }
        }
#endif
    }
}

#Preview {
    AsyncPreview(operation: { try await PreviewComposition.withDemoData() }) { composition in
        ContentView(composition: composition)
    }
}
