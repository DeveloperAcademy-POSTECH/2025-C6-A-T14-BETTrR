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
                    .aspectRatio(1, contentMode: .fit)
                
                Text(script.title)
                    .foregroundStyle(.normalBlack900)
                    .font(.calloutRegular16)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(EdgeInsets(top: 16, leading: 16, bottom: 24, trailing: 16))
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
    .frame(width: 200)
    .environment(NavigationRouter())
}
