//
//  ScriptDashboardView.swift
//  Bettr
//
//  Created by 길정수 on 11/4/25.
//

import SwiftUI

struct ScriptDashboardView: View {
    var viewModel: ScriptDashboardViewModel
    
    var body: some View {
        Group {
            if viewModel.scriptDashboardData != nil {
                GeometryReader { geometry in
                    VStack(alignment: .leading, spacing: 30) {
                        ScriptDashboardTopContents(viewModel: viewModel)
                            .frame(height: geometry.size.height * 0.4)
                        
                        ScriptDashboardBottomContents(viewModel: viewModel)
                            .frame(height: geometry.size.height * 0.6)
                    }
                }
                .padding(.horizontal, 60)
                .padding(.bottom, 60)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .navigationBarTitleDisplayMode(.inline)
            } else {
                // 로딩, 에러 뷰
                DashboardLoadingView(
                    isLoading: !viewModel.showingError,
                    errorMessage: viewModel.errorMessage
                )
                
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(viewModel.scriptDashboardData?.title ?? "")
        .onAppear {
            viewModel.onAppear()
        }
    }
}

struct ScriptDashboardTopContents: View {
    @Environment(NavigationRouter.self) var router
    var viewModel: ScriptDashboardViewModel
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(viewModel.scriptDashboardData?.sentences ?? [], id: \.orderIndex) { sentence in
                        Text(sentence.englishText)
                            .font(.system(size: 20))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: .infinity, alignment: .top)
            
            Button(action: {
                router.push(Route.memorization(scriptId: viewModel.scriptId))
            }) {
                Text("암기하기")
                    .foregroundStyle(.white)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 50)
                    .background(
                        RoundedRectangle(cornerRadius: 100)
                            .fill(Color.blue)
                    )
                    .glassEffect()
            }
        }
        .padding(.vertical, 25)
        .padding(.horizontal, 40)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.primary.opacity(0.05))
                .strokeBorder(Color.primary.opacity(0.5), lineWidth: 1)
        )
    }
}

struct ScriptDashboardBottomContents: View {
    @Environment(NavigationRouter.self) var router
    var viewModel: ScriptDashboardViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("피드백 히스토리")
                .font(.system(size: 30, weight: .bold))
            
            if let feedbacks = viewModel.scriptDashboardData?.feedbacks, !feedbacks.isEmpty {
                
                GeometryReader { geometry in
                    HStack(spacing: 0) {
                        let sortedFeedbacks = feedbacks.sorted { $0.createdAt > $1.createdAt }
                        let recentFeedbacks = sortedFeedbacks.prefix(5)
                        let top3Words = viewModel.scriptDashboardData?.top3IncorrectWords ?? []
                        
                        // 왼쪽 섹션
                        FeedbackHistoryGraphAndStatistics(feedbackCount: sortedFeedbacks.count, top3IncorrectWords: top3Words)
                            .padding(.horizontal, 20)
                            .frame(width: geometry.size.width * 0.5)
                        
                        // 오른쪽 섹션
                        VStack(alignment: .leading, spacing: 20) {
                            ForEach(recentFeedbacks, id: \.createdAt) { feedback in
                                Button(action: {
                                    router.push(Route.HistoricalFeedback(summary: feedback))
                                }) {
                                    FeedbackSummaryCard(feedback: feedback)
                                }
                                .foregroundStyle(Color.primary)
                            }
                        }
                        .padding(.horizontal, 20)
                        .frame(width: geometry.size.width * 0.5, alignment: .leading)
                        .frame(maxHeight: .infinity, alignment: .top)
                    }
                }
            }
            else {
                VStack {
                    Spacer() // 텍스트를 세로 중앙에 배치
                    Text("아직 피드백이 없습니다")
                        .font(.system(size: 18))
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.primary.opacity(0.05))
                        .strokeBorder(Color.primary.opacity(0.5), lineWidth: 1)
                )
            }
        }
    }
}

struct FeedbackHistoryGraphAndStatistics: View {
    let feedbackCount: Int
    let top3IncorrectWords: [IncorrectWordCount]
    
    var body: some View {
        VStack(spacing: 16) {
            Text("그래프")
                .padding(.vertical, 25)
                .padding(.horizontal, 40)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.primary.opacity(0.05))
                )
            
            
            HStack(spacing: 16) {
                VStack(spacing: 16) {
                    Text("최근 \(feedbackCount < 5 ? feedbackCount : 5)회 중 많이 틀린 단어")
                        .font(.system(size: 18, weight: .bold))
                    if top3IncorrectWords.isEmpty {
                        Text("데이터가 없습니다.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        // 가져온 Top 3 데이터를 리스트로 표시
                        ForEach(Array(top3IncorrectWords.enumerated()), id: \.offset) { index, item in
                            HStack {
                                Text("\(index + 1). \(item.word)")
                                    .font(.system(size: 16, weight: .semibold))
                                Spacer()
                                Text("\(item.count)회")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .padding(.vertical, 25)
                .padding(.horizontal, 40)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.primary.opacity(0.05))
                )
                
                VStack(spacing: 16) {
                    Text("누적 피드백")
                    Text("\(feedbackCount)")
                }
                .padding(.vertical, 25)
                .padding(.horizontal, 40)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.primary.opacity(0.05))
                )
            }
        }
    }
}

struct FeedbackSummaryCard: View {
    let feedback: FeedbackSummary
    
    private static var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()
    
    private func formatPracticeDuration(duration: Double) -> String {
        let totalSeconds = duration
        
        let minutes = Int(totalSeconds) / 60
        let seconds = Int(totalSeconds) % 60
        
        // 밀리초 계산
        let milliseconds = Int((totalSeconds - floor(totalSeconds)) * 100)
        
        // "dd:dd.dd" (mm:ss.SS) 포맷
        return String(format: "%02d:%02d.%02d", minutes, seconds, milliseconds)
    }
    
    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle().fill(Color.gray.opacity(0.5))
                Text("\(Int(feedback.totalScore * 100))%")
            }
            .frame(width: 60, height: 60)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(formatPracticeDuration(duration: feedback.practiceDuration))
                Text("누락된 단어 \(feedback.missingWordCount) | 추가된 단어 \(feedback.addedWordCount) | 대체된 단어 \(feedback.replacedWordCount)")
            }
            
            Spacer()
            
            Text(Self.dateFormatter.string(from: feedback.createdAt))
        }
    }
}
