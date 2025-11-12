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
        HStack(alignment: .top, spacing: 16) {
            
            // 자주 틀린 단어
            VStack(alignment: .leading, spacing: 0) {
                Text("자주 틀린 단어 Top 3")
                    .font(.calloutRegular16)
                    .foregroundStyle(.normalBlack900)
                
                Spacer()
                
                VStack(alignment: .center) {
                    if top3IncorrectWords.isEmpty {
                        Text("데이터가 충분하지 않아요")
                            .font(.labelBold16)
                    } else {
                        VStack(spacing: 24) {
                            ForEach(top3IncorrectWords, id: \.id) { item in
                                Text("\(item.word)")
                                    .font(.subbodyBold24)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .foregroundStyle(.normalBlack900)
                
                Spacer()
            }
            .cardBorder(padding: 24)
            
            // 누적 피드백, 평균 녹음 시간
            VStack(spacing: 16) {
                StatisticCard(title: "누적 피드백") {
                    HStack(alignment: .bottom, spacing: 4) {
                        Text("\(feedbackCount)")
                            .font(.subtitleBold32)
                        
                        Text("회")
                            .font(.calloutRegular20)
                    }
                }
                
                StatisticCard(title: "평균 녹음 시간") {
                    Text(averagePracticeDuration.asPracticeDurationString())
                        .font(.subtitleBold32)
                }
            }
            .foregroundStyle(.normalBlack900)
            .frame(maxWidth: 200)
        }
    }
}
