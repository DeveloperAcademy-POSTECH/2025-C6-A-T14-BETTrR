import SwiftUI

struct HomeView: View {
    @Environment(DatabaseContainer.self) var container
    
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
    
    @Environment(NavigationRouter.self) var router
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Scripts")
                    .font(.system(size: 25, weight: .semibold))
                
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
                    // 새 스크립트 추가 버튼
                    Button(action: {
                        router.push(Route.scriptInput)
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
                    ForEach(scripts.prefix(5)) { script in
                        ScriptCard(script: script)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

struct FeedbackHistorySectionView: View {
    @Environment(DatabaseContainer.self) var container
    @State private var feedbackSummaries: [FeedbackSummary] = []
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Feedback History")
                    .font(.system(size: 25, weight: .bold))
                    .padding(.top, 15)
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
            
            VStack(spacing: 12) {
                ForEach(feedbackSummaries.prefix(3)) { summary in
                    FeedbackItemView(feedbackSummary: summary)
                }
            }
            .padding(.horizontal, 20)
        }
        .onAppear {
            loadFeedbackSummaries()
        }
        .alert("오류", isPresented: $showingError) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private func loadFeedbackSummaries() {
        do {
            // Fetch all scripts to get their IDs, then fetch practice sessions for each script
            let allScripts = try container.scriptManagementService.fetchAllScripts()
            var allFeedbackSummaries: [FeedbackSummary] = []
            
            for script in allScripts {
                if let scriptId = script.id {
                    let practiceSessions = try container.practiceSessionService.fetchPracticeSessions(forScriptId: scriptId)
                    for session in practiceSessions {
                        if let sessionId = session.id {
                            if let summary = try container.practiceSessionService.fetchFeedbackSummary(forPracticeSessionId: sessionId) {
                                allFeedbackSummaries.append(summary)
                            }
                        }
                    }
                }
            }
            // Sort by analyzedAt in descending order to show recent feedback
            feedbackSummaries = allFeedbackSummaries.sorted { $0.analyzedAt > $1.analyzedAt }
        } catch {
            errorMessage = "피드백 요약을 불러오는데 실패했습니다: \(error.localizedDescription)"
            showingError = true
        }
    }
}

// MARK: - Script Card Component

struct ScriptCard: View {
    @Environment(NavigationRouter.self) var router
    
    let script: Script
    
    var body: some View {
        Button(action: {
            if let scriptId = script.id {
                router.push(Route.memorization(scriptId: scriptId))
            } else {
                // id가 nil인 경우
                print("Error: script.id가 nil이어서 네비게이션할 수 없습니다.")
            }        }){
                VStack(alignment: .leading, spacing: 8) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray)
                        .frame(width: 200, height: 150)
                    
                    Text(script.title)
                        .foregroundStyle(Color.primary)
                        .font(.system(size: 15))
                        .lineLimit(2)
                        .frame(width: 200, alignment: .leading)
                }
            }
    }
}

struct FeedbackItemView: View {
    @Environment(DatabaseContainer.self) var container
    let feedbackSummary: FeedbackSummary
    @State private var scriptTitle: String = ""
    @State private var practiceSessionDuration: Double = 0.0
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.gray)
                .frame(width: 80, height: 80)
                .overlay(
                    Text("\(Int(feedbackSummary.totalScore))%")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(scriptTitle)
                    .font(.system(size: 16, weight: .semibold))
                Text(formatDuration(practiceSessionDuration))
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                Text("추가된 단어 \(feedbackSummary.addedWordCount) | 누락된 단어 \(feedbackSummary.missingWordCount) | 대체된 단어 \(feedbackSummary.replacedWordCount)")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Text(formatDate(feedbackSummary.analyzedAt))
                .font(.system(size: 14))
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .onAppear {
            loadRelatedData()
        }
        .alert("오류", isPresented: $showingError) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private func loadRelatedData() {
        do {
            if let practiceSession = try container.practiceSessionService.fetchPracticeSession(id: feedbackSummary.practiceSessionId) {
                practiceSessionDuration = practiceSession.totalPresentationTime
                if let script = try container.scriptManagementService.fetchScript(id: practiceSession.scriptId) {
                    scriptTitle = script.title
                }
            }
        } catch {
            errorMessage = "관련 데이터를 불러오는데 실패했습니다: \(error.localizedDescription)"
            showingError = true
        }
    }
    
    private func formatDuration(_ duration: Double) -> String {
        let minutes = Int(duration / 60)
        let seconds = Int(duration.truncatingRemainder(dividingBy: 60))
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter.string(from: date)
    }
}
