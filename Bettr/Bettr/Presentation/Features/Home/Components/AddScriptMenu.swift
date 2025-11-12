//
//  AddMenu.swift
//  Bettr
//
//  Created by oliver on 11/12/25.
//

import SwiftUI

struct AddScriptMenu: View {
    let onSelectPhoto: () -> Void
    let onTakePhoto: () -> Void
    let onSelectFile: () -> Void
    @Binding var showMenu: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            MenuItemButton(icon: "photo", title: "사진 보관함") {
                onSelectPhoto()
                showMenu = false
            }
            MenuItemButton(icon: "camera", title: "사진 찍기") {
                onTakePhoto()
                showMenu = false
            }
            MenuItemButton(icon: "doc", title: "파일 선택") {
                onSelectFile()
                showMenu = false
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 8)
        .frame(width: 238)
        .glassEffect(.regular, in: .rect(cornerRadius: 34))
    }
}

private struct MenuItemButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.primary)
                    .frame(width: 28)
                
                Text(title)
                    .font(.calloutRegular16)
                    .foregroundColor(.primary)
                    .padding(.leading, 4)
                    .padding(.vertical, 11)
                
                Spacer()
            }
            .padding(.horizontal, 8)
        }
    }
}

#Preview {
    ZStack(alignment: .top) {
        Color.primaryBlue500
            .frame(width: 150, height: 50)
        AddScriptMenu(onSelectPhoto: {}, onTakePhoto: {}, onSelectFile: {}, showMenu: .constant(true))
    }
}
