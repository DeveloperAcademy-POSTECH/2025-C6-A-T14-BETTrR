import SwiftUI

struct ScriptGridView: View {
    @Environment(DatabaseContainer.self) var container
    
    let onSelectPhoto: () -> Void
    let onTakePhoto: () -> Void
    let onSelectFile: () -> Void
    let requestDelete: (Script) -> Void
    
    @Binding var showMenu: Bool
    
    // 4-column grid layout
    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 36),
        GridItem(.flexible(), spacing: 36),
        GridItem(.flexible(), spacing: 36),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack {
            LazyVGrid(columns: columns, spacing: 60) {
                AddNewScriptCard(
                    onSelectPhoto: onSelectPhoto,
                    onTakePhoto: onTakePhoto,
                    onSelectFile: onSelectFile,
                    showMenu: $showMenu
                )
                .padding(EdgeInsets(top: 16, leading: 16, bottom: 24, trailing: 16))
                
                ForEach(container.scripts) { script in
                    ScriptCard(script: script, onDelete: {
                        requestDelete(script)
                    })
                    .padding(EdgeInsets(top: 16, leading: 16, bottom: 24, trailing: 16))
                }
            }
        }
        .background(Color.gray.opacity(0.1))
    }
}

#Preview {
    ScriptGridView(
        onSelectPhoto: {},
        onTakePhoto: {},
        onSelectFile: {},
        requestDelete: { _ in },
        showMenu: .constant(false)
    )
    .environment(DatabaseContainer.getForPreview())
    .environment(NavigationRouter())
}

