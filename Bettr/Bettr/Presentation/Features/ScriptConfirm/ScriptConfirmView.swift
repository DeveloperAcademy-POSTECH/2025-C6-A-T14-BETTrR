import SwiftUI

// MARK: - 화면 UI
struct ScriptConfirmView: View {
    @Environment(DatabaseContainer.self) var databaseContainer
    @Environment(NavigationRouter.self) var router

    @State var scriptTitle: String = ""
    @State var scriptContent: String = ""
    @State var isLoading: Bool = false
    @State private var isEditingContent = false
    @State private var isEditingTitle = false
    @FocusState private var isTitleFocused: Bool

    // Gemini 분석 결과 임시 저장
    // .onChange에서 이 값을 감지하여 저장 및 화면 이동
    @State var parsedScript: ScriptData?

    @State var showErrorAlert: Bool = false
    @State var errorMessage: String = ""
    
    init(initialText: String? = nil) {
        _scriptContent = State(initialValue: initialText ?? "")
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // 1. 제목 입력 필드 (메모 앱처럼 동작)
            if isEditingTitle {
                TextField("스크립트 제목", text: $scriptTitle)
                    .font(.title)
                    .fontWeight(.bold)
                    .focused($isTitleFocused)
                    .onSubmit {
                        isEditingTitle = false
                    }
                    .padding(.horizontal)
            } else {
                Text(scriptTitle.isEmpty ? "스크립트 제목" : scriptTitle)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(scriptTitle.isEmpty ? .gray : .primary)
                    .padding(.horizontal)
                    .onTapGesture {
                        isEditingTitle = true
                        isTitleFocused = true
                    }
            }

            // 2. 스크립트 내용 (메모 앱처럼 동작)
            if isEditingContent {
                TextEditor(text: $scriptContent)
                    .padding(4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.5))
                    )
                    .padding(.horizontal)
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
                .padding(.horizontal)
                .onTapGesture {
                    isEditingContent = true
                }
            }
            
            // 3. 분석 및 저장 버튼
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
        .navigationTitle("스크립트 확인")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
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
        .alert("오류", isPresented: $showErrorAlert) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .onChange(of: parsedScript) { oldValue, newValue in
            guard let scriptData = newValue else {
                // Gemini 응답이 nil인 경우 (파싱 실패 등) 에러 처리
                showErrorAlert("AI 응답을 처리할 수 없습니다.\n\n다시 시도해주세요.")
                return
            }
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
                    try await databaseContainer.wordExtractionService.extractAndSaveWords(for: scriptId)
                    print("✅ 단어 추출 및 저장이 완료되었습니다.")
                    
                    // MainActor를 사용하여 UI 업데이트 (화면 이동)
                    await MainActor.run {
                        router.push(Route.memorization(scriptId: scriptId))
                    }
                }
            }
            catch {
                print("🔥 스크립트 저장 또는 화면 이동 오류:", error.localizedDescription)
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
        But my teacher told me, “Mistakes are part of learning.”
        So I decided to join the English speech contest.
        At first, I was really nervous, but I didn’t give up.
        When I finished, I felt proud of myself.
        That experience taught me to be brave.
        Now I know every challenge helps me grow.
        Thank you for listening.
        """)
            .environment(DatabaseContainer.getForPreview())
            .environment(NavigationRouter())
    }
}