//
//  ScriptCard.swift
//  Bettr
//
//  Created by oliver on 11/11/25.
//


import SwiftUI
import PhotosUI

struct ScriptCard: View {
    @Environment(NavigationRouter.self) var router
    
    let script: Script
    let onDelete: () -> Void
    
    var body: some View {
        Button(action: {
            if let scriptId = script.id {
                router.push(Route.scriptDashboard(scriptId: scriptId))
            }
        }) {
            VStack(alignment: .leading, spacing: 12) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(.primaryBlue200)
                
                Text(script.title)
                    .foregroundStyle(.normalBlack900)
                    .font(.calloutRegular16)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 193)
            .frame(maxWidth: .infinity)
        }
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label("삭제", systemImage: "trash")
            }
        }
    }
}

#Preview {
    ScriptCard(
        script: Script(
            id: 1,
            title: "Sample Script Title",
            createdAt: Date(),
            lastViewedAt: Date()
        ),
        onDelete: {}
    )
    .environment(NavigationRouter())
}
