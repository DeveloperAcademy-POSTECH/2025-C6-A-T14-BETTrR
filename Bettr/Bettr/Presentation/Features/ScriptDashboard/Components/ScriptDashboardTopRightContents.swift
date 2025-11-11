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
    
    @Environment(\.metrics) var metrics
    
    var body: some View {
        HStack(spacing: metrics.topRightStackSpacing) {
            
            // 자주 틀린 단어
            VStack(alignment: .leading) {
                Text("자주 틀린 단어 Top 3")
                    .font(.system(size: metrics.font16, weight: .regular))
                    .foregroundStyle(.normalBlack900)
                
                Spacer()
                
                VStack(alignment: .center) {
                    if top3IncorrectWords.isEmpty {
                        Text("데이터가 충분하지 않아요")
                            .font(.system(size: metrics.font16, weight: .bold))
                    } else {
                        VStack(spacing: metrics.topRightStackSpacing) {
                            ForEach(top3IncorrectWords, id: \.id) { item in
                                Text("\(item.word)")
                                    .font(.system(size: metrics.font24, weight: .bold))
                            }
                        }
                    }
                }
                .foregroundStyle(.normalBlack900)
                .frame(maxWidth: .infinity)
                
                Spacer()
            }
            .dashboardCardStyle(
                padding: metrics.cardPadding24,
                style: .border(.primaryBlue200)
            )
            
            // 누적 피드백, 평균 녹음 시간
            VStack(spacing: metrics.topRightStackSpacing) {
                StatisticCard(title: "누적 피드백") {
                    HStack(alignment: .bottom, spacing: 4) {
                        Text("\(feedbackCount)")
                            .font(.system(size: metrics.font32, weight: .bold))

                        Text("회")
                            .font(.system(size: metrics.font20, weight: .regular))
                    }
                }
                
                StatisticCard(title: "평균 녹음 시간") {
                    Text(averagePracticeDuration.asPracticeDurationString())
                        .font(.system(size: metrics.font32, weight: .bold))
                }
            }
            .foregroundStyle(.normalBlack900)
        }
    }
}
