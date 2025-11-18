//
//  EnglishScriptTextView.swift
//  Bettr
//
//  Created by 길정수 on 11/3/25.
//

import SwiftUI

struct EnglishScriptTextView: View {
    let text: String
    let isHidden: Bool
    let isHighlighted: Bool
    let onTap: () -> Void

    var body: some View {
        Text(text)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .font(.bodyRegular24)
            .opacity(isHidden ? 0 : 1)
            .background(
                RoundedRectangle(cornerRadius: 2)
                    .fill(.normalGray200)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .stroke(isHighlighted ? .primaryBlue300 : .clear, lineWidth: 4)
            )
            .onTapGesture(perform: onTap)
    }
}
