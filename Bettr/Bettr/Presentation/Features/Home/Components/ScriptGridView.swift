import SwiftUI

struct ScriptGridView: View {
    @Environment(DatabaseContainer.self) var container
    
    let columns: [GridItem]
    let onSelectPhoto: () -> Void
    let onTakePhoto: () -> Void
    let onSelectFile: () -> Void
    let requestDelete: (Script) -> Void
    
    var body: some View {
        VStack {
            LazyVGrid(columns: columns, spacing: 20) {
                AddNewScriptCard(
                    onSelectPhoto: onSelectPhoto,
                    onTakePhoto: onTakePhoto,
                    onSelectFile: onSelectFile
                )
                
                ForEach(container.scripts) { script in
                    ScriptCard(script: script, onDelete: {
                        requestDelete(script)
                    })
                }
            }
        }
        .padding(30)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
        .padding(.horizontal, 40)
    }
}

#Preview {
    ScriptGridView(
        columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
        onSelectPhoto: {},
        onTakePhoto: {},
        onSelectFile: {},
        requestDelete: { _ in }
    )
    .environment(DatabaseContainer.getForPreview())
    .environment(NavigationRouter())
}

