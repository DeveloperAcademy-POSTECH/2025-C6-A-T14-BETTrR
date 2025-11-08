//
//  EditableTitleView.swift
//  Bettr
//
//  Created by 길정수 on 11/8/25.
//

import SwiftUI

struct EditableTitleView: View {
    @Binding var title: String
    
    let showEditIcon: Bool
    
    @State private var isEditing: Bool = false
    @State private var editedTitle: String = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        if isEditing {
            // --- 수정 중일 때 ---
            HStack(spacing: 8) {
                TextField("제목을 입력하세요", text: $editedTitle)
                    .font(.headline)
                    .textFieldStyle(.plain)
                    .focused($isFocused)
                    .onSubmit { saveAndExit() }
                                
                // 텍스트가 있을 때만 X 버튼 표시
                if !editedTitle.isEmpty {
                    Button(action: {
                        editedTitle = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(minWidth: 200)
            .padding(.horizontal, 12)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.1))
            )
            .onChange(of: isFocused) {
                if !isFocused {
                    saveAndExit()
                }
            }
            .onAppear {
                editedTitle = title
                isFocused = true
            }
        } else {
            // --- 수정 중이 아닐 때 ---
            HStack(spacing: 4) {
                Text(title)
                    .font(.headline)
                
                if showEditIcon {
                    Image(systemName: "chevron.down.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                editedTitle = title
                isEditing = true
            }
        }
    }
    
    private func saveAndExit() {
        if !editedTitle.isEmpty && editedTitle != title {
            title = editedTitle
        }
        isEditing = false
    }
}
