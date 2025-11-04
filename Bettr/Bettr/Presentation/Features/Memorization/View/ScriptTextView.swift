//
//  ScriptTextView.swift
//  Bettr
//
//  Created by 길정수 on 11/3/25.
//

import SwiftUI

struct ScriptTextView: View {
    let text: String
    let fontSize: CGFloat
    let isHidden: Bool
    let isHighlighted: Bool
    let onTap: () -> Void // 탭 이벤트를 부모에게 전달

    var body: some View {
        Text(text)
            .font(.system(size: fontSize))
            .opacity(isHidden ? 0 : 1)
            .background(
                RoundedRectangle(cornerRadius: 2)
                    .fill(isHidden ? Color.primary.opacity(0.05) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 2)
                            .stroke(isHighlighted ? Color.primary : Color.clear, lineWidth: 1)
                    )
            )
            .onTapGesture(perform: onTap)
    }
}
