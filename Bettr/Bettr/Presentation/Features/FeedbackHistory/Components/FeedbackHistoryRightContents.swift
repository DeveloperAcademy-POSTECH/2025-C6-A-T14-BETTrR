//
//  FeedbackHistoryRightContents.swift
//  Bettr
//
//  Created by 길정수 on 11/20/25.
//


import SwiftUI
import Charts

struct FeedbackHistoryRightContents: View {
    let viewModel: FeedbackHistoryViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("피드백 히스토리")
                    .font(.subbodyBold24)
                    .padding(8)
                
                FeedbackHistoryList(viewModel: viewModel)
                    .padding(.leading, 16)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .cardBordered(padding: 36)
    }
}