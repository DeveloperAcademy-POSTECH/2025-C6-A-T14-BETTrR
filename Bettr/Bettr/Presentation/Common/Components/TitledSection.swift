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
    let titleFont: Font
    let content: Content
    
    init(
        title: String,
        subtitle: String? = nil,
        spacing: CGFloat = 16,
        titleFont: Font = .subbodyBold24,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.spacing = spacing
        self.titleFont = titleFont
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            // 타이틀
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text(title)
                    .font(titleFont)
                    .padding(8)
                
                
                // subtitle이 있을 때만 렌더링
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.calloutRegular16)
                        .padding(8)
                }
            }
            .foregroundStyle(.normalBlack900)
            .fixedSize(horizontal: true, vertical: false)
            
            // 콘텐츠
            content
        }
    }
}

extension TitledSection {
    /// 제목이 크고 간격이 넓은 '결과 화면용' 이니셜라이저 (프리셋)
    static func large(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> TitledSection {
        TitledSection(
            title: title,
            spacing: 24,
            titleFont: .headingBold28,
            content: content
        )
    }
}
