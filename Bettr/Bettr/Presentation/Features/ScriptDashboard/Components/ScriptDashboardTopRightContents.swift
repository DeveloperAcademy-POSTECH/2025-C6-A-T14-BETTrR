//
//  ScriptDashboardTopRightContents.swift
//  Bettr
//
//  Created by 길정수 on 11/6/25.
//

import SwiftUI

struct ScriptDashboardTopRightContents: View {
    
    let stats: ScriptDashboardStats?

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            
            // 자주 틀린 단어
            VStack(alignment: .leading, spacing: 0) {
                Text("자주 틀린 단어 Top 3")
                    .font(.calloutRegular16)
                    .foregroundStyle(.normalBlack900)
                
                Spacer()
                
                VStack(alignment: .center) {
                    if let top3Words = stats?.top3IncorrectWords, !top3Words.isEmpty {
                        VStack(spacing: 16) {
                            ForEach(top3Words, id: \.id) { item in
                                Text("\(item.word)")
                                    .font(.subbodyBold24)
                            }
                        }
                    } else {
                        Text("데이터가 충분하지 않아요")
                            .font(.labelBold16)
                    }
                }
                .frame(maxWidth: .infinity)
                .foregroundStyle(.normalBlack900)
                
                Spacer()
            }
            .cardBordered(padding: 24)
            
            // 누적 피드백, 평균 녹음 시간
            VStack(spacing: 16) {
                DiagonalLayoutCard(title: "누적 피드백") {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(stats?.feedbackCount ?? 0)")
                            .font(.subbodyBold24)
                        Text("회")
                            .font(.calloutRegular20)
                    }
                }
                .cardBordered()
                
                DiagonalLayoutCard(title: "평균 녹음 시간") {
                    Text(stats?.averagePracticeDuration.asPracticeDurationString() ?? "0s")
                        .font(.subbodyBold24)
                }
                .cardBordered()
            }
            .foregroundStyle(.normalBlack900)
            .frame(width: 158)
        }
        .frame(maxWidth: .infinity, maxHeight: 272)
    }
}

// MARK: - Preview

fileprivate struct MockStatsData {
    
    static let fullStats = ScriptDashboardStats(
        feedbackCount: 128,
        top3IncorrectWords: [
            .init(word: "Actually", count: 15),
            .init(word: "Specific", count: 10),
            .init(word: "Example", count: 5)
        ],
        averagePracticeDuration: 123.5, // "2m 3s"
        recentFeedbackCount: 10
    )

}

#Preview("데이터가 풍부한 경우") {
    ScriptDashboardTopRightContents(stats: MockStatsData.fullStats)
}
