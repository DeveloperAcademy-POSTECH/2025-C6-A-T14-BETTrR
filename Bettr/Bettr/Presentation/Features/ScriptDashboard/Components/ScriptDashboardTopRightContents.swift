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
            VStack(alignment: .leading) {
                Text("자주 틀린 단어 Top 3")
                    .font(.system(size: 18, weight: .bold))
                
                Spacer()
                
                VStack(alignment: .center) {
                    if top3IncorrectWords.isEmpty {
                        Text("데이터가 충분하지 않아요")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        ForEach(top3IncorrectWords, id: \.id) { item in
                            Text("\(item.word)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                
                Spacer()
            }
            .dashboardCardStyle()
            
            // 누적 피드백, 평균 녹음 시간
            VStack(spacing: 16) {
                StatisticCard(title: "누적 피드백") {
                    HStack(alignment: .bottom) {
                        Text("\(feedbackCount)")
                            .font(.system(size: 32, weight: .regular))
                        Text("회")
                            .font(.system(size: 20, weight: .regular))
                    }
                }
                
                StatisticCard(title: "평균 녹음 시간") {
                    Text(averagePracticeDuration.asPracticeDurationString())
                        .font(.system(size: 32, weight: .regular))
                }
            }
        }
    }
}
