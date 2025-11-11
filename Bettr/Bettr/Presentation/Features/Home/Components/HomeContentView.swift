import SwiftUI

struct HomeContentView: View {
    @Environment(DatabaseContainer.self) var container
    
    let columns: [GridItem]
    let onSelectPhoto: () -> Void
    let onTakePhoto: () -> Void
    let onSelectFile: () -> Void
    let requestDelete: (Script) -> Void
    
    var body: some View {
        if container.scripts.isEmpty {
            EmptyScriptsView(
                onSelectPhoto: onSelectPhoto,
                onTakePhoto: onTakePhoto,
                onSelectFile: onSelectFile
            )
            .frame(height: 500) // 적절한 높이 설정
        } else {
            ScriptGridView(
                columns: columns,
                onSelectPhoto: onSelectPhoto,
                onTakePhoto: onTakePhoto,
                onSelectFile: onSelectFile,
                requestDelete: requestDelete
            )
        }
    }
}

#Preview("Empty Scripts") {
    HomeContentView(
        columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
        onSelectPhoto: {},
        onTakePhoto: {},
        onSelectFile: {},
        requestDelete: { _ in }
    )
    .environment(DatabaseContainer.getForPreview(withMockData: false))
    .environment(NavigationRouter())
}

#Preview("With Scripts") {
    HomeContentView(
        columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
        onSelectPhoto: {},
        onTakePhoto: {},
        onSelectFile: {},
        requestDelete: { _ in }
    )
    .environment(DatabaseContainer.getForPreview(withMockData: true))
    .environment(NavigationRouter())
}
