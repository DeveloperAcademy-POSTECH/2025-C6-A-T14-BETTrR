//
//  KoreanScriptTextView.swift
//  Bettr
//
//  Created by 길정수 on 11/9/25.
//

import SwiftUI

struct KoreanScriptTextView: View {
    let text: String
    let isVisible: Bool

    var body: some View {
        Text(text)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .font(.calloutRegular16)
            .opacity(isVisible ? 1 : 0)
    }
}
