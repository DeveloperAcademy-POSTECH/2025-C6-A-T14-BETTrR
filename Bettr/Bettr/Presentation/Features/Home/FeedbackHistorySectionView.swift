import SwiftUI

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
            let allSummaries = try container.scriptManagementService.fetchAllFeedbackSummaries()
            feedbackSummaries = allSummaries.sorted { $0.createdAt > $1.createdAt }
        } catch {
            errorMessage = "피드백 요약을 불러오는데 실패했습니다: \(error.localizedDescription)"
            showingError = true
        }
    }
}

struct FeedbackItemView: View {
    @Environment(DatabaseContainer.self) var container
    let feedbackSummary: FeedbackSummary
    @State private var scriptTitle: String = ""
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
                Text(formatDuration(feedbackSummary.practiceDuration))
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                Text("추가된 단어 \(feedbackSummary.addedWordCount) | 누락된 단어 \(feedbackSummary.missingWordCount) | 대체된 단어 \(feedbackSummary.replacedWordCount)")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Text(formatDate(feedbackSummary.createdAt))
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
            if let script = try container.scriptManagementService.fetchScript(id: feedbackSummary.scriptId) {
                scriptTitle = script.title
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

#Preview {
    FeedbackHistorySectionView()
        .environment(DatabaseContainer.getForPreview())
}
