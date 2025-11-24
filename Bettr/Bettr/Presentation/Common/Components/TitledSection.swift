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
        spacing: CGFloat,
        titleFont: Font,
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
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text(title)
                    .font(titleFont)
                    .padding(8)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.calloutRegular16)
                        .padding(8)
                }
            }
            .foregroundStyle(.normalBlack900)
            .fixedSize(horizontal: true, vertical: false)
            
            content
        }
    }
}

extension TitledSection {
    /// 일반적인 섹션 스타일 (spacing: 16, font: subbodyBold24)
    static func standard(
        title: String,
        subtitle: String? = nil,
        spacing: CGFloat = 16,
        @ViewBuilder content: () -> Content
    ) -> TitledSection {
        TitledSection(
            title: title,
            subtitle: subtitle,
            spacing: spacing,
            titleFont: .subbodyBold24,
            content: content
        )
    }
    
    /// 결과 화면용 큰 스타일 (spacing: 24, font: headingBold28)
    static func large(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder content: () -> Content
    ) -> TitledSection {
        TitledSection(
            title: title,
            subtitle: subtitle,
            spacing: 24,
            titleFont: .headingBold28,
            content: content
        )
    }
}
