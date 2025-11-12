//
//  AddNewScriptCard.swift
//  Bettr
//
//  Created by oliver on 11/11/25.
//


import SwiftUI
import PhotosUI

struct AddNewScriptCard: View {
    let onSelectPhoto: () -> Void
    let onTakePhoto: () -> Void
    let onSelectFile: () -> Void
    
    @Binding var showMenu: Bool
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .stroke(style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                .foregroundColor(Color.gray.opacity(0.3))
            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    showMenu = true
                }
            }) {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 56, height: 56)
                    .overlay(
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.white)
                    )
                    .glassEffect()
            }
            .overlay(alignment: .top) {
                if showMenu {
                    AddScriptMenu(
                        onSelectPhoto: onSelectPhoto,
                        onTakePhoto: onTakePhoto,
                        onSelectFile: onSelectFile,
                        showMenu: $showMenu
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.8, anchor: .top)))
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .contentShape(Rectangle())
    }
}

#Preview {
    AddNewScriptCard(onSelectPhoto: {}, onTakePhoto: {}, onSelectFile: {}, showMenu: .constant(false))
        .frame(width: 200)
}
