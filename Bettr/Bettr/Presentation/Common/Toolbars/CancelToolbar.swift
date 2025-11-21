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
    @Environment(NavigationRouter.self) var router
    
    let isXmark: Bool
    
    init(isXmark: Bool = false) {
        self.isXmark = isXmark
    }
    
    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        if let dismissAction = modalDismiss {
                            router.reset()
                            dismissAction()
                        } else {
                            defaultDismiss()
                        }
                    }) {
                        let showXmark = modalDismiss != nil || isXmark
                        Image(systemName: showXmark ? "xmark" : "chevron.left")
                            .fontWeight(.semibold)
                    }
                }
            }
    }
}

extension View {
    func cancelToolbar(isXmark: Bool = false) -> some View {
        self.modifier(CancelToolbar(isXmark: isXmark))
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
