import SwiftUI

struct ScriptGridView: View {
    let scripts: [Script]
    let onSelectPhoto: () -> Void
    let onTakePhoto: () -> Void
    let onSelectFile: () -> Void
    let requestDelete: (Script) -> Void
    
    @available(iOS 16.0, *)
    private var centeredFlowLayout: CenteredFixedSizeFlowLayout {
        CenteredFixedSizeFlowLayout(
            itemSize: CGSize(width: 220, height: 270),
            horizontalSpacing: 50,
            verticalSpacing: 20
        )
    }
    
    var body: some View {
        ScrollView {
            if #available(iOS 16.0, *) {
                centeredFlowLayout {
                    AddNewScriptCard(
                        onSelectPhoto: onSelectPhoto,
                        onTakePhoto: onTakePhoto,
                        onSelectFile: onSelectFile
                    )
                    .padding(EdgeInsets(top: 16, leading: 16, bottom: 24, trailing: 16))
                    
                    ForEach(scripts) { script in
                        ScriptCard(script: script, onDelete: {
                            requestDelete(script)
                        })
                        .padding(EdgeInsets(top: 16, leading: 16, bottom: 24, trailing: 16))
                    }
                }
                .padding(.top, 76)
            } else {
                // Fallback on earlier versions
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 220))], spacing: 60) {
                    AddNewScriptCard(
                        onSelectPhoto: onSelectPhoto,
                        onTakePhoto: onTakePhoto,
                        onSelectFile: onSelectFile
                    )
                    .padding(EdgeInsets(top: 16, leading: 16, bottom: 24, trailing: 16))
                    
                    ForEach(scripts) { script in
                        ScriptCard(script: script, onDelete: {
                            requestDelete(script)
                        })
                        .padding(EdgeInsets(top: 16, leading: 16, bottom: 24, trailing: 16))
                    }
                }
                .padding(.top, 76)
            }
        }
        .scrollIndicators(.hidden)
    }
}

#Preview {
    ScriptGridView(
        scripts: [
            Script(id: 1, title: "Sample Script 1", createdAt: Date(), lastViewedAt: Date()),
            Script(id: 2, title: "Sample Script 2", createdAt: Date(), lastViewedAt: Date()),
            Script(id: 3, title: "Sample Script 3", createdAt: Date(), lastViewedAt: Date())
        ],
        onSelectPhoto: {},
        onTakePhoto: {},
        onSelectFile: {},
        requestDelete: { _ in }
    )
    .environment(NavigationRouter())
}
