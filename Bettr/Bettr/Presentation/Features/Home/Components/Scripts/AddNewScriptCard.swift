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
    
    var body: some View {
        Circle()
            .fill(.primaryBlue500)
            .frame(width: 48, height: 48)
            .overlay(
                Image(systemName: "plus")
                    .font(.labelBold16)
                    .foregroundColor(.defaultWhite50)
            )
            .glassEffect()
            .overlay(
                AddScriptMenuView(
                    onSelectPhoto: onSelectPhoto,
                    onTakePhoto: onTakePhoto,
                    onSelectFile: onSelectFile
                )
            )
            .frame(height: 193)
            .frame(maxWidth: .infinity)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .inset(by: 1)
                    .stroke(.primaryBlue200, style: StrokeStyle(lineWidth: 2, dash: [8, 8]))
            )
    }
}

#Preview {
    AddNewScriptCard(onSelectPhoto: {}, onTakePhoto: {}, onSelectFile: {})
}
