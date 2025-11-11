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
            VStack {
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
                //TODO: 동적 대응 생각해서 수정
                .offset(y: -47)
                Spacer()
            }
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
