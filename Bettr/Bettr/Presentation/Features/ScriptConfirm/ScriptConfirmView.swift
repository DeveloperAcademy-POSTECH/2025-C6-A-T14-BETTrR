//
//  ScriptInputView.swift
//  Bettr
//
//  Created by 서세린 on 10/28/25.
//

import SwiftUI
import FirebaseAI

// MARK: - 화면 UI
struct ScriptConfirmView: View {
    @Environment(DatabaseContainer.self) var databaseContainer

    @State var inputscriptText: String = """
    Hello everyone, my name is Dewy.
    Today, I want to talk about the power of challenge.
    I used to be afraid of speaking English in front of others.
    But my teacher told me, “Mistakes are part of learning.”
    So I decided to join the English speech contest.
    At first, I was really nervous, but I didn’t give up.
    When I finished, I felt proud of myself.
    That experience taught me to be brave.
    Now I know every challenge helps me grow.
    Thank you for listening.
    """
    @State var isLoading: Bool = false              // FirebaseAI 호출 중 로딩 상태
    @State  var isEditing: Bool = false
    @FocusState var editorFocused: Bool

    @State var parsedScript: ScriptData?     // Gemini 분석 후 결과 저장(추가)
    @State var showErrorAlert: Bool = false         // 🆕 추가: 사용자 에러 알림
    @State var errorMessage: String = ""            // 🆕 추가: Alert에 표시될 메시지
    
    init(initialText: String? = nil) {
        _inputscriptText = State(initialValue: initialText ?? """
    Hello everyone, my name is Dewy.
    Today, I want to talk about the power of challenge.
    I used to be afraid of speaking English in front of others.
    But my teacher told me, “Mistakes are part of learning.”
    So I decided to join the English speech contest.
    At first, I was really nervous, but I didn’t give up.
    When I finished, I felt proud of myself.
    That experience taught me to be brave.
    Now I know every challenge helps me grow.
    Thank you for listening.
    """)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            HStack{
                Text("영어 스크립트를 입력하세요")
                    .font(.headline)
                Button(action: {
                    // 편집 모드 토글
                    withAnimation {
                        isEditing.toggle()
                        // 편집 모드 전환 시 포커스 제어
                        editorFocused = isEditing
                    }
                }) {
                    Text(isEditing ? "편집 완료" : "편집")
                        .bold()
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .frame(minWidth: 90)
                        .background(isEditing ? Color.blue : Color.gray.opacity(0.2))
                        .foregroundColor(isEditing ? .white : .primary)
                        .cornerRadius(8)
                }
                // 편집 중이면 간단 안내 텍스트
                if isEditing {
                    Text("편집 중..")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            
            // 텍스트 입력창 (편집 비허용 상태에서는 disabled)
            ScrollView {
                TextEditor(text: $inputscriptText)
                    .focused($editorFocused)
                    .disabled(!isEditing)
                    .padding(4) // Add some inner padding for the text
                    .background(isEditing ? Color.yellow.opacity(0.08) : Color.clear)
            }
            .frame(height: 300)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.gray.opacity(0.5))
            )
            .padding(.horizontal)
            .opacity(isEditing ? 1.0 : 0.95)
            
            // Gemini 호출 버튼
            Button(action: {
                Task {
                    await callGemini()
                }
            }) {
                if isLoading {
                    ProgressView("Gemini가 분석 중...")
                        .tint(.white)
                } else {
                    Text("Gemini에게 분석 요청")
                        .bold()
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            (isEditing || isLoading || inputscriptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            ? Color.gray
                            : Color.blue
                        )
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .disabled(inputscriptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading || isEditing)
            .padding(.horizontal)
            
            // 결과 표시 (파싱 버전 삽입용)
            if let script = parsedScript {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(script.sentences, id: \.orderIndex) { sentence in
                            VStack(alignment: .leading, spacing: 8) {
                                Text("🗣️ Sentence \(sentence.orderIndex + 1)")
                                    .font(.headline)
                                
                                GroupBox(label: Text("영문 문장")) {
                                    Text(sentence.englishText)
                                }
                                GroupBox(label: Text("자연스러운 번역")) {
                                    Text(sentence.koreanText)
                                }
                                
                                GroupBox(label: Text("청크 매칭")) {
                                    ForEach(sentence.chunks, id: \.orderIndex) { chunk in
                                        VStack(alignment: .leading) {
                                            Text("EN: \(chunk.englishText)")
                                            Text("KR: \(chunk.koreanText)")
                                                .foregroundColor(.secondary)
                                        }
                                        .padding(.vertical, 2)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            } else {
                Text("아직 분석 결과가 없습니다.")
                    .foregroundColor(.gray)
            }
        }
        .padding()
        // 🆕 Alert 추가
        .alert("오류", isPresented: $showErrorAlert) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - 사용자 알림 (UI Thread 전환)
    @MainActor
    func showErrorAlert(_ message: String) {
        self.errorMessage = message
        self.showErrorAlert = true
    }
}

#Preview {
    ScriptConfirmView(initialText: nil)
        .environment(DatabaseContainer.getForPreview())
        .environment(NavigationRouter())
}
