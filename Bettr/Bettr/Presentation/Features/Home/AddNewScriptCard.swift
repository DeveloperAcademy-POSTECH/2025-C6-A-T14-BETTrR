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
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .stroke(style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                .foregroundColor(Color.gray.opacity(0.3))
            
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
        .aspectRatio(1, contentMode: .fit)
        .contentShape(Rectangle())
        .overlay {
            Menu {
                Button(action: onSelectPhoto) {
                    Label("사진 보관함", systemImage: "photo")
                }
                Button(action: onTakePhoto) {
                    Label("사진 찍기", systemImage: "camera")
                }
                Button(action: onSelectFile) {
                    Label("파일 선택", systemImage: "doc")
                }
            } label: {
                Color.clear
            }
        }
    }
}

#Preview {
    AddNewScriptCard(onSelectPhoto: {}, onTakePhoto: {}, onSelectFile: {})
        .frame(width: 200)
}
