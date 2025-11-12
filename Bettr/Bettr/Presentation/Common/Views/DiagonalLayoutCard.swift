//
//  SmallBorderCard.swift
//  Bettr
//
//  Created by 길정수 on 11/10/25.
//

import SwiftUI

struct DiagonalLayoutCard<Content: View>: View {
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
    }
}
