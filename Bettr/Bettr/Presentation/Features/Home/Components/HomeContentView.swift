import SwiftUI

struct HomeContentView: View {
    let scripts: [Script]?
    let isLoading: Bool
    let errorMessage: String?
    let onRetry: () -> Void
    
    let onSelectPhoto: () -> Void
    let onTakePhoto: () -> Void
    let onSelectFile: () -> Void
    let requestDelete: (Script) -> Void
    
    var body: some View {
        if let scripts {
            if let errorMessage {
                HStack {
                    Text(errorMessage)
                    Button("다시 시도", action: onRetry)
                }
                .padding(.horizontal, 84)
            }
            if scripts.isEmpty {
                VStack {
                    Spacer()
                    Spacer()
                    HStack {
                        Spacer()
                        EmptyScriptsView(
                            onSelectPhoto: onSelectPhoto,
                            onTakePhoto: onTakePhoto,
                            onSelectFile: onSelectFile
                        )
                        Spacer()
                    }
                    Spacer()
                    Spacer()
                    Spacer()
                }
            } else {
                ScriptGridView(
                    scripts: scripts,
                    onSelectPhoto: onSelectPhoto,
                    onTakePhoto: onTakePhoto,
                    onSelectFile: onSelectFile,
                    requestDelete: requestDelete
                )
                .padding(.horizontal, 125)
            }
        } else {
            Spacer()
            if isLoading {
                ProgressView()
            } else if let errorMessage {
                VStack(spacing: 16) {
                    Text(errorMessage)
                    Button("다시 시도", action: onRetry)
                }
            } else {
                Button("목록 불러오기", action: onRetry)
            }
            Spacer()
        }
    }
}

#Preview("Empty Scripts") {
    HomeContentView(
        scripts: [], isLoading: false, errorMessage: nil, onRetry: {},
        onSelectPhoto: {}, onTakePhoto: {}, onSelectFile: {}, requestDelete: { _ in }
    )
}

#Preview("With Scripts") {
    AsyncPreview(operation: {
        let composition = try await PreviewComposition.withDemoData()
        let model = composition.makeHomeListModel()
        await model.refresh()
        return model
    }) { model in
        HomeContentView(
            scripts: model.scripts, isLoading: false, errorMessage: nil, onRetry: {},
            onSelectPhoto: {}, onTakePhoto: {}, onSelectFile: {}, requestDelete: { _ in }
        )
        .environment(NavigationRouter())
    }
}
