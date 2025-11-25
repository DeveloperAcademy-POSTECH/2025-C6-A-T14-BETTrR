//
//  ChartLegendItem.swift
//  Bettr
//
//  Created by 길정수 on 11/23/25.
//

import SwiftUI

/// 차트에 표시되는 범례 아이템 (색상 원 + 텍스트)
struct ChartLegendItem: View {
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
