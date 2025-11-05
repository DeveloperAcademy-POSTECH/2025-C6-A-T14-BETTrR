import SwiftUI

struct HomeView: View {
    @Environment(DatabaseContainer.self) var container
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                ScriptsSectionView(scripts: container.scripts)
            }
        }
        .onAppear {
            container.refreshScripts()
        }
    }
}

#Preview {
    HomeView()
        .environment(DatabaseContainer.getForPreview())
        .environment(NavigationRouter())
}
