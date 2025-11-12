//
//  ResultTopContents.swift
//  Bettr
//
//  Created by 길정수 on 11/12/25.
//

import SwiftUI

struct ResultTopContents: View {
    let model: FeedbackResultModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("피드백 결과 요약")
                .font(.headingBold28)
                .foregroundStyle(.normalBlack900)
            
            ResultSummaryGridView(model: model)
        }
    }
}

struct ResultSummaryGridView: View {
    let model: FeedbackResultModel
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    DiagonalLayoutCard(title: "스크립트 제목") {
                        HStack(alignment: .bottom, spacing: 4) {
                            Text(model.scriptTitle)
                                .font(.subbodyBold24)
                        }
                    }
                    .cardBordered(padding: 24)
                    
                    DiagonalLayoutCard(title: "피드백 회차") {
                        HStack(alignment: .bottom, spacing: 4) {
                            Text("\(model.feedbackNumber)")
                                .font(.subtitleBold32)
                            
                            Text("번")
                                .font(.calloutRegular20)
                        }
                    }
                    .cardBordered(padding: 24)
                    .frame(maxWidth: 192)
                }
                .frame(maxHeight: 116)
                
                HStack(spacing: 16) {
                    DiagonalLayoutCard(title: "총 녹음 시간") {
                        HStack(alignment: .bottom, spacing: 4) {
                            Text(model.totalRecordingTime.toMMSSms())
                                .font(.subbodyBold24)
                        }
                    }
                    .cardBordered(padding: 24)
                    .frame(minWidth: 200)
                    
                    DiagonalLayoutCard(title: "누락된 단어") {
                        HStack(alignment: .bottom, spacing: 4) {
                            Text("\(model.missingCount)")
                                .font(.subbodyBold24)
                            
                            Text("개")
                                .font(.calloutRegular16)
                        }
                    }
                    .cardBordered(padding: 24)
                    .frame(maxWidth: 150)
                    
                    DiagonalLayoutCard(title: "대체된 단어") {
                        HStack(alignment: .bottom, spacing: 4) {
                            Text("\(model.replacedCount)")
                                .font(.subbodyBold24)
                            
                            Text("개")
                                .font(.calloutRegular16)
                        }
                    }
                    .cardBordered(padding: 24)
                    .frame(maxWidth: 150)
                    
                    DiagonalLayoutCard(title: "추가된 단어") {
                        HStack(alignment: .bottom, spacing: 4) {
                            Text("\(model.extraCount)")
                                .font(.subbodyBold24)
                            
                            Text("개")
                                .font(.calloutRegular16)
                        }
                    }
                    .cardBordered(padding: 24)
                    .frame(maxWidth: 150)
                }
                .frame(maxHeight: 120)
            }
            
            DiagonalLayoutCard(title: "종합 평가 점수") {
                HStack(alignment: .bottom, spacing: 4) {
                    Text("\(Int(model.accuracy * 100))")
                        .font(.labelMedium64)
                    
                    Text("%")
                        .font(.bodyRegular24)
                }
            }
            .cardBordered(padding: 24)
            .frame(maxWidth: 229, maxHeight: 242)
        }
    }
}
