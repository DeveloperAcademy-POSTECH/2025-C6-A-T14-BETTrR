//
//  PerfectResultBottomView.swift
//  Bettr
//
//  Created by 길정수 on 11/14/25.
//


import SwiftUI

struct PerfectResultBottomView: View {
    var body: some View {
        TitledSection.large(title: "틀린 문장 모아보기") {
            VStack {
                Spacer()
                
                Text("틀린 문장이 하나도 없습니다.")
                    .font(.labelBold16)
                    .foregroundStyle(.normalBlack900)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .cardBorderedFilled(padding: 36)
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }
}

#Preview {
    PerfectResultBottomView()
}
