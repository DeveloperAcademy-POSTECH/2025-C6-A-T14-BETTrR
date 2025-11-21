//
//  LegendContent.swift
//  Bettr
//
//  Created by 길정수 on 11/21/25.
//

import SwiftUI

struct LegendItem: View {
    let color: Color
    let text: String
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(text)
                .font(.footerRegular11)
                .foregroundStyle(.normalGray600)
        }
    }
}

struct LegendContent: View {
    var body: some View {
        HStack(spacing: 12) {
            LegendItem(color: .secondaryBlue700, text: "점수")
            LegendItem(color: .alertRed01, text: "평균")
        }
    }
}
