//
//  StatisticCard.swift
//  Bettr
//
//  Created by 길정수 on 11/10/25.
//

import SwiftUI

struct StatisticCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content
    
    @Environment(\.metrics) var metrics
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.system(size: metrics.font16, weight: .regular))
                .foregroundStyle(.normalBlack900)
            
            Spacer()
            
            HStack {
                Spacer()
                content()
            }
        }
        .dashboardCardStyle(
            top: metrics.cardPadding24,
            leading: metrics.cardPadding24,
            bottom: metrics.cardPadding24,
            trailing: metrics.cardPadding16,
            style: .border(.primaryBlue200)
        )
    }
}
