//
//  ScriptTextView.swift
//  Bettr
//
//  Created by 길정수 on 11/3/25.
//

import SwiftUI

struct ScriptTextView: View {
    let text: String
    let font: Font
    let isBackground: Bool
    let isHidden: Bool
    let isHighlighted: Bool
    let isVisible: Bool
    let onTap: () -> Void

    var body: some View {
        Text(text)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .font(font)
            .opacity(isHidden || !isVisible ? 0 : 1)
            .background(
                RoundedRectangle(cornerRadius: 2)
                    .fill(isBackground ? .G_1 : .clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 2)
                            .stroke(isHighlighted ? .pp2L2 : .clear, lineWidth: 4)
                    )
            )
            .onTapGesture(perform: onTap)
    }
}
