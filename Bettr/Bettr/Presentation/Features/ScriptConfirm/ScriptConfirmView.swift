import SwiftUI

// MARK: - 화면 UI
struct ScriptConfirmView: View {
    @Environment(DatabaseContainer.self) var databaseContainer
    @Environment(NavigationRouter.self) var router
    @Environment(\.dismiss) private var dismiss
    
    @State var scriptTitle: String
    @State var scriptContent: String
    @State var isLoading: Bool = false
    @State private var isEditingContent = false
    
    // Gemini 분석 결과 임시 저장
    @State var parsedScript: ScriptData?
    
    @State var showErrorAlert: Bool = false
    @State var errorMessage: String = ""
    
    // 뒤로가기 확인 알림
    @State private var showBackAlert: Bool = false
    @State private var isPendingDismiss: Bool = false
    
    init(initialText: String?, initialTitle: String?) {
        let content = initialText ?? ""
        _scriptContent = State(initialValue: String(content.prefix(2000)))
        _scriptTitle = State(initialValue: initialTitle ?? "")
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // 스크립트 내용 (메모 앱처럼 동작)
            VStack(alignment: .trailing, spacing: 8) {
                if isEditingContent {
                    TextEditor(text: $scriptContent)
                        .padding(4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray.opacity(0.5))
                        )
                } else {
                    ScrollView {
                        Text(scriptContent)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(10)
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.5))
                    )
                    .onTapGesture {
                        isEditingContent = true
                    }
                }
                
                // 글자 수 표시
                Text("\(scriptContent.count) / 2000")
                    .font(.caption)
                    .foregroundColor(scriptContent.count == 2000 ? .red : .gray)
            }
            .padding(.horizontal)
            
            // 분석 및 저장 버튼
            Button(action: {
                Task {
                    await callGemini()
                }
            }) {
                AnalyzeButtonLabel(isLoading: isLoading)
            }
            .disabled(scriptContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading || isEditingContent)
            .padding(.horizontal)
        }
        .padding()
        .navigationTitle(scriptTitle.isEmpty ? "새 스크립트" : scriptTitle)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    showBackAlert = true
                }) {
                    Image(systemName: "chevron.left")
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                if isEditingContent {
                    Button(action: {
                        isEditingContent = false
                    }) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .alert("진행 상황을 잃게 됩니다", isPresented: $showBackAlert) {
            Button("취소", role: .cancel) {}
            Button("나가기", role: .destructive) {
                dismiss()
            }
        } message: {
            Text("이 화면을 나가면 작성 중인 내용이 저장되지 않습니다.")
        }
        .alert("오류", isPresented: $showErrorAlert) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .onChange(of: scriptContent) { oldValue, newValue in
            if newValue.count > 2000 {
                scriptContent = String(newValue.prefix(2000))
            }
        }
        .onChange(of: parsedScript) { oldValue, newValue in
            guard let scriptData = newValue else { return }
            saveAndNavigate(with: scriptData)
        }
    }
    
    // MARK: - 저장 및 화면 이동
    private func saveAndNavigate(with scriptData: ScriptData) {
        Task {
            do {
                // 사용자가 입력한 제목이 비어있으면, Gemini가 생성한 제목 사용
                let finalTitle = scriptTitle.isEmpty ? scriptData.title : scriptTitle
                let scriptToSave = ScriptData(title: finalTitle, sentences: scriptData.sentences)
                
                let script = try databaseContainer.scriptManagementService.createScript(scriptData: scriptToSave)
                print("✅ 스크립트가 성공적으로 저장되었습니다.")
                
                if let scriptId = script.id {
                    do {
                        try await databaseContainer.wordExtractionService.extractAndSaveWords(for: scriptId)
                        print("✅ 단어 추출 및 저장이 완료되었습니다.")
                    } catch WordExtractionError.deviceNotSupported {
                        // TODO: 이 부분은 임시방편이므로, 더 나은 아키텍처로 개선 필요.
                        print("⚠️ 단어 추출 건너뜀: 기기가 지원되지 않습니다.")
                    } catch {
                        print("🔥 단어 추출 중 오류 발생:", error.localizedDescription)
                    }
                    
                    // MainActor를 사용하여 UI 업데이트 (화면 이동)
                    await MainActor.run {
                        router.push(Route.memorization(scriptId: scriptId))
                    }
                }
            } catch {
                print("🔥 스크립트 저장 오류:", error.localizedDescription)
                await MainActor.run {
                    showErrorAlert("스크립트를 저장하는 데 실패했습니다.")
                }
            }
        }
    }
    
    // MARK: - 사용자 알림 (UI Thread 전환)
    @MainActor
    func showErrorAlert(_ message: String) {
        self.errorMessage = message
        self.showErrorAlert = true
    }
}

// MARK: - AnalyzeButtonLabel Component
private struct AnalyzeButtonLabel: View {
    @Environment(\.isEnabled) private var isEnabled
    let isLoading: Bool
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Gemini가 분석 중...")
                    .tint(.white)
            } else {
                Text("분석 및 암기 시작")
                    .bold()
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(isEnabled ? Color.blue : Color.gray)
        .foregroundColor(.white)
        .cornerRadius(10)
    }
}

#Preview {
    NavigationStack {
        ScriptConfirmView(initialText: """
        Hello everyone, my name is Dewy.
        Today, I want to talk about the power of challenge.
        I used to be afraid of speaking English in front of others.
        But my teacher told me, "Mistakes are part of learning."
        So I decided to join the English speech contest.
        At first, I was really nervous, but I didn't give up.
        When I finished, I felt proud of myself.
        That experience taught me to be brave.
        Now I know every challenge helps me grow.
        Thank you for listening.
        """, initialTitle: "Dewy's Speech")
        .environment(DatabaseContainer.getForPreview())
        .environment(NavigationRouter())
    }
}
