//
//  CancelToolbar.swift
//  Bettr
//
//  Created by 길정수 on 10/30/25.
//

import SwiftUI

struct CancelToolbar: ViewModifier {
    @Environment(\.dismiss) var dismiss
    
    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                    }
                }
            }
    }
}

extension View {
    func cancelToolbar() -> some View {
        self.modifier(CancelToolbar())
    }
}
