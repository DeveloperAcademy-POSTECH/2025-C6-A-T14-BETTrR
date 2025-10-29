//
//  ScriptInputView.swift
//  Bettr
//
//  Created by 서세린 on 10/28/25.
//

import SwiftUI

struct ScriptInputView: View {
    @State private var scriptText: String = ""       // 사용자가 입력한 스크립트 저장용 변수
    @State private var savedScript: String = ""      // 임시 저장된 스크립트

    var body: some View {
        VStack(spacing: 20) {
            Text("영어 스크립트를 입력하세요")
                .font(.headline)

            // 텍스트 입력창
            TextEditor(text: $scriptText)
                .frame(height: 300)
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.5))
                )
                .padding(.horizontal)

            // 저장 버튼
            Button(action: {
                savedScript = scriptText.trimmingCharacters(in: .whitespacesAndNewlines)
            }) {
                Text("저장")
                    .font(.title3)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)

            // 저장된 스크립트 미리보기
            if !savedScript.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("저장된 스크립트:")
                        .font(.headline)
                    Text(savedScript)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
                .padding(.horizontal)
            }

            Spacer()
        }
        .padding(.top)
    }
}

#Preview {
    ScriptInputView()
}
