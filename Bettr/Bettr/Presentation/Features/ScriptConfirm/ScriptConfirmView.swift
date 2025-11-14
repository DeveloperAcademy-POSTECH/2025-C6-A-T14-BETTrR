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
    @State private var isTitleEditing: Bool = false
    
    // TextEditor 포커스 상태 감지용 (버튼 제어)
    @FocusState private var isFocusedContentEditor: Bool
    
    // Gemini 분석 결과 임시 저장
    @State var parsedScript: ScriptData?
    
    @State var showErrorAlert: Bool = false
    @State var errorMessage: String = ""
    
    // 뒤로가기 확인 알림
    @State private var showBackAlert: Bool = false
    @State private var isPendingDismiss: Bool = false
    
    // 글자 수 제한
    private static let maxCharacterCount = 2000
    
    //Gemini 호출 로직 전용 객체 (ScriptGeminiCall.swift에 정의됨)
    private let geminiCaller = ScriptGeminiCall()
    
    //Local Rate Limiter(사용자의 호출 제한)
    private let rateLimiter = LocalRateLimiter.shared
    
    init(initialText: String?, initialTitle: String?) {
        let content = initialText ?? ""
        _scriptContent = State(initialValue: String(content.prefix(Self.maxCharacterCount)))
        _scriptTitle = State(initialValue: initialTitle ?? "")
    }
    
    var body: some View {
        VStack {
            // 스크립트 내용
            VStack(alignment: .trailing, spacing: 8) {
                if isEditingContent {
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $scriptContent)
                            .padding(4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.primaryBlue200, lineWidth: 3)
                            )
                            .focused($isFocusedContentEditor)
                        //placeholder
                        if scriptContent.isEmpty {
                            Text("스크립트를 입력하세요.")
                                .foregroundColor(.gray.opacity(0.5))
                                .padding(.vertical, 12)
                                .padding(.horizontal, 8)
                        }
                    }
                } else {
                    ScrollView {
                        Text(scriptContent)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(10)
                    }
                    .overlay(alignment: .bottom) {
                        Rectangle()
                            .fill(Color.primaryBlue200)
                            .frame(height: 4)
                    }
                    .onTapGesture {
                        isEditingContent = true
                        isFocusedContentEditor = true
                    }
                }
                
                // 글자 수 표시
                Text("\(scriptContent.count) / \(Self.maxCharacterCount)")
                    .font(.caption)
                    .foregroundColor(scriptContent.count == Self.maxCharacterCount ? .red : .secondaryBlue700)
            }
            .contentShape(Rectangle())
            .padding(.horizontal, 80)
            .padding(.top, 36)
            .onTapGesture {
                isTitleEditing = false
                isEditingContent = false
                isFocusedContentEditor = false
            }
        }
        .safeAreaInset(edge: .bottom){
            if !isFocusedContentEditor{
                // 분석 및 저장 버튼
                Button(action: {
                    Task {
                        // LocalRateLimiter 검사 추가
                        guard rateLimiter.canCall() else {
                            await MainActor.run {
                                showErrorAlert("요청이 너무 잦습니다.\n잠시 후 다시 시도해주세요.")
                            }
                            return
                        }
                        await callGemini()
                    }
                }) {
                    Text("분석 및 암기 시작")
                        .bold()
                }
                .buttonStyle(GeneralButtonStyle(width: 404))
                .frame(width: 404, height: 48)
                .padding(.vertical, 10)
                .disabled(scriptContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
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
            
            ToolbarItem(placement: .principal) {
                EditableTitle(
                    title: $scriptTitle,
                    showEditIcon: true,
                    isEditing: $isTitleEditing
                )
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
            if newValue.count > Self.maxCharacterCount {
                scriptContent = String(newValue.prefix(Self.maxCharacterCount))
            }
        }
        .onChange(of: parsedScript) { oldValue, newValue in
            guard let scriptData = newValue else { return }
            saveAndNavigate(with: scriptData)
        }
        .fullScreenCover(isPresented: $isLoading) {
            ScriptConfirmLoadingView()
        }
    }
    
    // MARK: -Gemini 두 번 호출: 스크립트 분석 → 단어 추출
    private func callGemini() async {
        isLoading = true
        
        do {
            print("🚀 [1/2] Gemini 스크립트 분석 시작")
            //ScriptGeminiCall.swift의 함수 호출 (JSON 반환)
            if let result = try await geminiCaller.analyzeScript(scriptContent) {
                await MainActor.run {
                    self.parsedScript = result
                }
                print("✅ [1/2] Gemini 스크립트 분석 완료 → ScriptData 생성됨")
            } else {
                throw URLError(.cannotParseResponse)
            }
        } catch {
            await MainActor.run {
                self.showErrorAlert("스크립트 분석 실패: \(error.localizedDescription)")
            }
            isLoading = false // Ensure isLoading is reset on error
            return
        }
    }
    
    // MARK: - 저장 및 화면 이동
    private func saveAndNavigate(with scriptData: ScriptData) {
        Task {
            defer { isLoading = false }
            do {
                // 사용자가 입력한 제목이 비어있으면, Gemini가 생성한 제목 사용
                let finalTitle = scriptTitle.isEmpty ? scriptData.title : scriptTitle
                let scriptToSave = ScriptData(title: finalTitle, sentences: scriptData.sentences)
                
                let script = try databaseContainer.scriptManagementService.createScript(scriptData: scriptToSave)
                print("✅ 스크립트가 성공적으로 저장되었습니다.")
                
                if let scriptId = script.id {
                    // MainActor를 사용하여 UI 업데이트 (화면 이동)
                    await MainActor.run {
                        router.reset() // Go back to HomeView
                        router.push(Route.scriptDashboard(scriptId: scriptId))
                        router.push(Route.memorization(scriptId: scriptId, scriptTitle: scriptTitle, currentFeedbackNumber: 0))
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
