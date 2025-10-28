//
//  ScriptInputView.swift
//  Bettr
//
//  Created by 서세린 on 10/28/25.
//

import SwiftUI

struct ScriptInputView: View {
    @State private var originalEnglishText: String = ""   // 입력된 스크립트를 저장할 변수

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("🎬 영어 스크립트 입력")
                .font(.title2)
                .bold()

            TextEditor(text: $originalEnglishText)
                .padding()
                .frame(height: 200)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .cornerRadius(12)
                .background(Color(UIColor.systemBackground))

            Button(action: {
                print("입력된 스크립트: \(originalEnglishText)")
            }) {
                Text("저장하기 (임시)")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(originalEnglishText.isEmpty ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(originalEnglishText.isEmpty) // 입력 없을 때 비활성화

            Spacer()
        }
        .padding()
    }
}

#Preview {
    ScriptInputView()
}
