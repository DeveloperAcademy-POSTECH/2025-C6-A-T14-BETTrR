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
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.calloutRegular16)
                .foregroundStyle(.normalBlack900)
            
            Spacer()
            
            HStack {
                Spacer()
                content()
            }
        }
        .dashboardCardStyle(
            top: 24, leading: 24, bottom: 24, trailing: 16,
            relativeTo: .callout,
            style: .border(.primaryBlue200)
        )
    }
}
