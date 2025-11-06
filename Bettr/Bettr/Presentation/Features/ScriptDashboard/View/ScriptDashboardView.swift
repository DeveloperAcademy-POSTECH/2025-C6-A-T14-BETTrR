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
    var viewModel: ScriptDashboardViewModel
    
    var body: some View {
        HStack(spacing: 16) {
            
            if let data = viewModel.scriptDashboardData, data.feedbackCount > 0 {
                GeometryReader { geometry in
                    HStack(spacing: 16) {
                        ScriptDashboardTopLeftContents()
                            .frame(width: geometry.size.width * 0.5, alignment: .leading)
                        
                        ScriptDashboardTopRightContents(
                            feedbackCount: data.feedbackCount,
                            top3IncorrectWords: data.top3IncorrectWords,
                            averagePracticeDuration: data.averagePracticeDuration,
                            recentFeedbackCount: data.recentFeedbackCount
                        )
                        .frame(width: geometry.size.width * 0.5, alignment: .leading)
                    }
                }
            }
        }
    }
}


struct ScriptDashboardTopLeftContents: View {
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
        }
    }
}

struct ScriptDashboardTopRightContents: View {
    let feedbackCount: Int
    let top3IncorrectWords: [IncorrectWordCount]
    let averagePracticeDuration: Double
    let recentFeedbackCount: Int

    var body: some View {
        HStack(spacing: 16) {
            
            // 자주 틀린 단어
            VStack(spacing: 16) {
                Text("최근 \(recentFeedbackCount)회 중 자주 틀린 단어")
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
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.primary.opacity(0.05))
            )
            
            // 누적 피드백, 평균 녹음 시간
            VStack(spacing: 16) {
                VStack(spacing: 16) {
                    Text("누적 피드백")
                    Text("\(feedbackCount)")
                }
                .padding(.vertical, 25)
                .padding(.horizontal, 40)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.primary.opacity(0.05))
                )
                
                VStack(spacing: 16) {
                    Text("평균 녹음 시간")
                    Text(averagePracticeDuration.asPracticeDurationString())
                }
                .padding(.vertical, 25)
                .padding(.horizontal, 40)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.primary.opacity(0.05))
                )
            }
        }
    }
}

struct ScriptDashboardBottomContents: View {
    var viewModel: ScriptDashboardViewModel
    
    var body: some View {
        HStack(spacing: 16) {
            if let data = viewModel.scriptDashboardData, data.feedbackCount > 0 {
                GeometryReader { geometry in
                    HStack(spacing: 16) {
                        
                        ScriptDashboardBottomLeftContents(feedbacks: data.recentFeedbacks)
                            .frame(width: geometry.size.width * 0.5, alignment: .leading)
                        
                        ScriptDashboardBottomRightContents(scriptId: viewModel.scriptId, sentences: data.sentences)
                            .frame(width: geometry.size.width * 0.5, alignment: .leading)
                        
                    }
                }
            }
        }
    }
}

struct ScriptDashboardBottomLeftContents: View {
    @Environment(NavigationRouter.self) var router
    var feedbacks: [FeedbackSummary]
    
    var body: some View {
        if feedbacks.count > 0 {
            VStack(alignment: .leading, spacing: 20) {
                ForEach(feedbacks, id: \.id) { feedback in
                    Button(action: {
                        router.push(Route.HistoricalFeedback(summary: feedback))
                    }) {
                        FeedbackSummaryCard(feedback: feedback)
                    }
                    .foregroundStyle(Color.primary)
                }
            }
            .frame(maxHeight: .infinity, alignment: .top)
        }
        else {
            VStack {
                Spacer()
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

struct ScriptDashboardBottomRightContents: View {
    @Environment(NavigationRouter.self) var router
    var scriptId: Int64
    var sentences: [ScriptDashboardSentenceModel]
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(sentences, id: \.orderIndex) { sentence in
                        Text(sentence.englishText)
                            .font(.system(size: 20))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: .infinity, alignment: .top)
            
            Button(action: {
                router.push(Route.memorization(scriptId: scriptId))
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

struct FeedbackSummaryCard: View {
    let feedback: FeedbackSummary
    
    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle().fill(Color.gray.opacity(0.5))
                Text("\(Int(feedback.totalScore * 100))%")
            }
            .frame(width: 60, height: 60)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(feedback.practiceDuration.asPracticeDurationString())
                Text("누락된 단어 \(feedback.missingWordCount) | 추가된 단어 \(feedback.addedWordCount) | 대체된 단어 \(feedback.replacedWordCount)")
            }
            
            Spacer()
            
            Text(feedback.createdAt.asAppDateString())
        }
    }
}
