import SwiftUI

struct HomeContentView: View {
    @Environment(DatabaseContainer.self) var container
    
    let onSelectPhoto: () -> Void
    let onTakePhoto: () -> Void
    let onSelectFile: () -> Void
    let requestDelete: (Script) -> Void
    
    var body: some View {
        if container.scripts.isEmpty {
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
                onSelectPhoto: onSelectPhoto,
                onTakePhoto: onTakePhoto,
                onSelectFile: onSelectFile,
                requestDelete: requestDelete
            )
            .padding(.horizontal, 125)
        }
    }
}

#Preview("Empty Scripts") {
    AsyncPreview(operation: {
        try await DatabaseContainer.getForPreview(withMockData: false)
    }) { container in
        HomeContentView(
            onSelectPhoto: {},
            onTakePhoto: {},
            onSelectFile: {},
            requestDelete: { _ in }
        )
        .environment(container)
        .environment(NavigationRouter())
    }
}

#Preview("With Scripts") {
    AsyncPreview(operation: {
        try await DatabaseContainer.getForPreview(withMockData: true)
    }) { container in
        HomeContentView(
            onSelectPhoto: {},
            onTakePhoto: {},
            onSelectFile: {},
            requestDelete: { _ in }
        )
        .environment(container)
        .environment(NavigationRouter())
    }
}
