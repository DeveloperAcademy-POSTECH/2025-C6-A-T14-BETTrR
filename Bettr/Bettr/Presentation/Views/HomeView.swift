import SwiftUI

struct HomeView: View {
    @EnvironmentObject var container: DatabaseContainer
    @State private var scripts: [Script] = []
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                ScriptsSectionView(scripts: scripts)
                
                FeedbackHistorySectionView()
                
                Spacer(minLength: 40)
            }
            .padding(.top, 20)
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadScripts()
        }
        .alert("오류", isPresented: $showingError) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private func loadScripts() {
        do {
            scripts = try container.scriptManagementService.fetchAllScripts()
        } catch {
            errorMessage = "스크립트를 불러오는데 실패했습니다: \(error.localizedDescription)"
            showingError = true
        }
    }
}

struct ScriptsSectionView: View {
    let scripts: [Script]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Scripts")
                    .font(.system(size: 34, weight: .bold))
                
                Spacer()
                
                Button(action: {
                    // TODO: Navigate to all scripts
                }) {
                    HStack(spacing: 4) {
                        Text("더보기")
                            .font(.system(size: 15))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 16) {
                    // Add New Script Button
                    Button(action: {
                        // TODO: Navigate to add script
                    }) {
                        VStack(alignment: .leading, spacing: 8) {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                                .foregroundColor(Color.gray.opacity(0.3))
                                .frame(width: 200, height: 150)
                                .overlay(
                                    Circle()
                                        .fill(Color.blue)
                                        .frame(width: 56, height: 56)
                                        .overlay(
                                            Image(systemName: "plus")
                                                .font(.system(size: 24, weight: .medium))
                                                .foregroundColor(.white)
                                        )
                                )
                            Text("새 스크립트 추가")
                                .font(.system(size: 15))
                                .lineLimit(2)
                                .frame(width: 200, alignment: .leading)
                                .foregroundColor(.primary)
                        }
                    }
                    
                    // Script Cards
                    ForEach(scripts.prefix(4)) { script in
                        ScriptCard(script: script)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

struct FeedbackHistorySectionView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Feedback History")
                    .font(.system(size: 34, weight: .bold))
                
                Spacer()
                
                Button(action: {
                    // TODO: Navigate to all feedback history
                }) {
                    HStack(spacing: 4) {
                        Text("더보기")
                            .font(.system(size: 15))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 20)
            
            // Placeholder for feedback history
            VStack(spacing: 12) {
                ForEach(0..<3) { index in
                    FeedbackHistoryPlaceholder()
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Script Card Component

struct ScriptCard: View {
    let script: Script
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray)
                .frame(width: 200, height: 150)
            
            Text(script.title)
                .font(.system(size: 15))
                .lineLimit(2)
                .frame(width: 200, alignment: .leading)
        }
    }
}

// MARK: - Feedback History Placeholder

struct FeedbackHistoryPlaceholder: View {
    var body: some View {
        HStack(spacing: 16) {
            ForEach(0..<2) { index in
                FeedbackItemView()
            }
        }
    }
}

struct FeedbackItemView: View {
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.gray)
                .frame(width: 80, height: 80)
                .overlay(
                    Text("68%")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text("스크립트 1.pdf")
                    .font(.system(size: 16, weight: .semibold))
                Text("dd:dd'dd")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                Text("추가된 단어 1 | 누락된 단어 2 | 대체된 단어 3")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Text("2021/13/12")
                .font(.system(size: 14))
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Preview

#Preview(traits: .landscapeLeft) {
    let database = try! AppDatabase.makeInMemory()
    let container = DatabaseContainer(database: database)
    
    // Add sample data
    let scriptData = ScriptData(
        title: "Sample Script 1",
        sentences: [
            SentenceData(
                orderIndex: 0,
                englishText: "Hello world",
                koreanText: "안녕 세상",
                chunks: [
                    ChunkData(orderIndex: 0, englishText: "Hello", koreanText: "안녕")
                ]
            )
        ]
    )
    
    _ = try? container.scriptManagementService.createScript(scriptData: scriptData)
    
    return HomeView()
        .environmentObject(container)
}
