//
//  EditableTitle.swift
//  Bettr
//
//  Created by 길정수 on 11/8/25.
//

import SwiftUI

/// 툴바 내 편집 가능한 제목
/// 제목에 대해 20자 제한을 둠
struct EditableTitle: View {
    @Binding var title: String
    let showEditIcon: Bool
    
    @Binding var isEditing: Bool
    @State private var editedTitle: String = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        Group {
            if isEditing {
                // --- 수정 중일 때 ---
                HStack(spacing: 8) {
                    TextField(
                        "",
                        text: $editedTitle,
                        prompt: Text("제목을 입력하세요")
                            .foregroundStyle(.normalGray600)
                    )
                    .foregroundStyle(.normalBlack900)
                    .textFieldStyle(.plain)
                    .focused($isFocused)
                    .onSubmit { saveAndExit() }
                    .onChange(of: editedTitle) {
                        if editedTitle.count > 20 {
                            editedTitle = String(editedTitle.prefix(20))
                        }
                    }
                    
                    // 텍스트가 있을 때만 X 버튼 표시
                    if !editedTitle.isEmpty {
                        Button(action: {
                            editedTitle = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(.primaryBlue300)
                        }
                    }
                }
                .frame(minWidth: 200)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.primaryBlue50)
                )
                .onAppear {
                    editedTitle = title
                    isFocused = true
                }
            } else {
                // --- 수정 중이 아닐 때 ---
                HStack(alignment: .center, spacing: 4) {
                    Text(title)
                        .foregroundStyle(.normalBlack900)
                    
                    if showEditIcon {
                        Image(systemName: "pencil.line")
                            .font(.system(size: 11))
                            .fontWeight(.black)
                            .foregroundStyle(.primaryBlue300)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    editedTitle = title
                    isEditing = true
                }
            }
        }
        .onChange(of: isEditing) {
            if isEditing {
                editedTitle = title
                isFocused = true
            } else {
                saveAndExit()
            }
        }
        .onChange(of: isFocused) {
            if isEditing && !isFocused {
                saveAndExit()
            }
        }
    }
    
    private func saveAndExit() {
        guard isEditing else { return }
        
        if !editedTitle.isEmpty && editedTitle != title {
            title = editedTitle
        }
        isEditing = false
    }
}
