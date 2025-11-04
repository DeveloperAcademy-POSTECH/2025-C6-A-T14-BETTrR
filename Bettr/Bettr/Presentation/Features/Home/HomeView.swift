import SwiftUI

struct HomeView: View {
    @Environment(DatabaseContainer.self) var container
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                ScriptsSectionView(scripts: container.scripts)
                
                FeedbackHistorySectionView()
                
                Spacer(minLength: 40)
            }
            .padding(.top, 20)
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
