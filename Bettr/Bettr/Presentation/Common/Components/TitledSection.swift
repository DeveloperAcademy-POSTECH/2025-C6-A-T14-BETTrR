//
//  TitledSection.swift
//  Bettr
//
//  Created by 길정수 on 11/23/25.
//

import SwiftUI

struct TitledSection<Content: View>: View {
    let title: String
    let subtitle: String?
    let spacing: CGFloat
    let content: Content
    
    init(
        title: String,
        subtitle: String? = nil,
        spacing: CGFloat = 16, // 기본값 16
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.spacing = spacing
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            // 타이틀
            HStack(alignment: .bottom, spacing: 0) {
                Text(title)
                    .font(.subbodyBold24)
                    .padding(8)
                    .border(.red)
                
                // subtitle이 있을 때만 렌더링
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.calloutRegular16)
                        .padding(8)
                        .border(.blue)
                }
            }
            .foregroundStyle(.normalBlack900)
            .fixedSize(horizontal: true, vertical: false)
            
            // 콘텐츠
            content
        }
    }
}
