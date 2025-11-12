import SwiftUI

struct HomeContentView: View {
    @Environment(DatabaseContainer.self) var container
    
    let onSelectPhoto: () -> Void
    let onTakePhoto: () -> Void
    let onSelectFile: () -> Void
    let requestDelete: (Script) -> Void
    
    @Binding var showMenu: Bool
    
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
                        onSelectFile: onSelectFile,
                        showMenu: $showMenu
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
                requestDelete: requestDelete,
                showMenu: $showMenu
            )
        }
    }
}

#Preview("Empty Scripts") {
    HomeContentView(
        onSelectPhoto: {},
        onTakePhoto: {},
        onSelectFile: {},
        requestDelete: { _ in },
        showMenu: .constant(false)
    )
    .environment(DatabaseContainer.getForPreview(withMockData: false))
    .environment(NavigationRouter())
}

#Preview("With Scripts") {
    HomeContentView(
        onSelectPhoto: {},
        onTakePhoto: {},
        onSelectFile: {},
        requestDelete: { _ in },
        showMenu: .constant(false)
    )
    .environment(DatabaseContainer.getForPreview(withMockData: true))
    .environment(NavigationRouter())
}
