//
//  CancelToolbar.swift
//  Bettr
//
//  Created by 길정수 on 10/30/25.
//

import SwiftUI

struct CancelToolbar: ViewModifier {
    @Environment(\.modalDismiss) var modalDismiss
    @Environment(\.dismiss) var defaultDismiss
    
    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        (modalDismiss ?? defaultDismiss)()
                    }) {
                        Image(systemName: "xmark")
                            .fontWeight(.semibold)
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

// MARK: - 커스텀 EnvironmentKey

private struct ModalDismissKey: EnvironmentKey {
    static let defaultValue: DismissAction? = nil
}

extension EnvironmentValues {
    var modalDismiss: DismissAction? {
        get { self[ModalDismissKey.self] }
        set { self[ModalDismissKey.self] = newValue }
    }
}
