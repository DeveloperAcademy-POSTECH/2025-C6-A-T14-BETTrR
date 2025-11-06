//
//  ScriptDashboardTopRightContents.swift
//  Bettr
//
//  Created by 길정수 on 11/6/25.
//

import SwiftUI

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
