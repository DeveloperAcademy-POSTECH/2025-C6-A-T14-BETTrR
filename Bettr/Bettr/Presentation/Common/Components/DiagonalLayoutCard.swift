//
//  SmallBorderCard.swift
//  Bettr
//
//  Created by 길정수 on 11/10/25.
//

import SwiftUI

/// 왼쪽 상단에 타이틀, 오른쪽 하단에 콘텐츠가 있는 형태의 카드 레이아웃
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
