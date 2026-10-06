import SwiftUI

// MARK: - 화면 UI
@MainActor
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

    @State var showErrorAlert: Bool = false
    @State var errorMessage: String = ""

    // 뒤로가기 확인 알림
    @State private var showBackAlert: Bool = false

    @State private var analysisTask: Task<Void, Never>?
    @State private var timeoutTask: Task<Void, Never>?
    @State private var activeRequestID: UUID?

    // 글자 수 제한
    private static let maxCharacterCount = 2000

    private let geminiCaller: ScriptGeminiCall

    // Local Rate Limiter(사용자의 호출 제한)
    private let rateLimiter = LocalRateLimiter.shared

    init(
        initialText: String?,
        initialTitle: String?,
        analyzer: (any ScriptAnalyzing)? = nil
    ) {
        geminiCaller = ScriptGeminiCall(analyzer: analyzer ?? FirebaseGeminiAdapter())
        let content = initialText ?? ""

        // 처음부터 영어/숫자/기호만 남김 (OCR에서 한국어 들어와도 여기서 제거됨)
        let asciiFiltered = content.unicodeScalars.filter { $0.isASCII }
        let cleaned = String(String.UnicodeScalarView(asciiFiltered))
        _scriptContent = State(initialValue: String(cleaned.prefix(Self.maxCharacterCount)))
        //        _scriptContent = State(initialValue: String(content.prefix(Self.maxCharacterCount)))
        _scriptTitle = State(initialValue: initialTitle ?? "")
    }

    var body: some View {
        VStack {
            // 스크립트 내용
            VStack(alignment: .trailing, spacing: 8) {
                if isEditingContent {
                    scriptContentEditor
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
                    .foregroundStyle(scriptContent.count == Self.maxCharacterCount ? .red : .secondaryBlue700)
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
        .safeAreaInset(edge: .bottom) {
            // 분석 및 저장 버튼
            Button(action: startAnalysis) {
                Text("분석 및 암기 시작")
                    .bold()
            }
            .buttonStyle(GeneralButtonStyle(width: 404))
            .frame(width: 404, height: 48)
            .padding(.bottom, 10)
            .disabled(scriptContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

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
        .alert("저장하지 않고 나가시겠어요?", isPresented: $showBackAlert) {
            Button("취소", role: .cancel) {}
            Button("나가기", role: .destructive) {
                cancelAnalysis()
                dismiss()
            }
        } message: {
            Text("편집 중인 스크립트는 저장되지 않고 삭제됩니다.")
        }
        .alert("오류", isPresented: $showErrorAlert) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .onChange(of: scriptContent) { _, newValue in
            if newValue.count > Self.maxCharacterCount {
                scriptContent = String(newValue.prefix(Self.maxCharacterCount))
            }
        }
        .onChange(of: router.path) { _, _ in cancelAnalysis() }
        .fullScreenCover(isPresented: $isLoading, onDismiss: loadingDismissed, content: {
            ScriptConfirmLoadingView()
        })
    }

    private var scriptContentEditor: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $scriptContent)
                .padding(4)
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.primaryBlue200, lineWidth: 3)
                }
                .focused($isFocusedContentEditor)

            if scriptContent.isEmpty {
                Text("스크립트를 입력하세요.")
                    .foregroundStyle(.gray.opacity(0.5))
                    .padding(.vertical, 12)
                    .padding(.horizontal, 8)
            }
        }
    }

    private func startAnalysis() {
        guard !isLoading else { return }
        guard rateLimiter.canCall() else {
            showErrorAlert("시스템 처리량이 초과되어 요청을 잠시 제한합니다.\n1분 후 다시 시도해 주세요.")
            return
        }

        isTitleEditing = false
        isLoading = true
        let requestID = UUID()
        let content = scriptContent
        let title = scriptTitle
        activeRequestID = requestID
        timeoutTask = Task {
            do {
                try await Task.sleep(for: .seconds(30))
            } catch {
                return
            }
            guard activeRequestID == requestID else { return }
            cancelAnalysis()
            showErrorAlert("네트워크 연결 상태를 확인해 주세요.\n연결에 문제가 없다면 잠시 후 다시 시도해 주세요.")
        }
        analysisTask = Task {
            await analyzeAndSave(content: content, title: title, requestID: requestID)
        }
    }

    private func loadingDismissed() {
        // An older cover dismissal must not cancel a newly accepted request.
        guard !isLoading else { return }
        cancelAnalysis()
    }

    private func cancelAnalysis() {
        activeRequestID = nil
        timeoutTask?.cancel()
        analysisTask?.cancel()
        timeoutTask = nil
        analysisTask = nil
        isLoading = false
    }

    private func analyzeAndSave(content: String, title: String, requestID: UUID) async {
        defer {
            if activeRequestID == requestID {
                activeRequestID = nil
                timeoutTask?.cancel()
                timeoutTask = nil
                analysisTask = nil
                isLoading = false
            }
        }

        let result: ScriptData
        do {
            result = try await geminiCaller.analyzeScript(content)
            guard activeRequestID == requestID, !Task.isCancelled else { return }
            timeoutTask?.cancel()
            timeoutTask = nil
        } catch {
            guard activeRequestID == requestID, !Task.isCancelled else { return }
            if (error as? AIError) != .cancelled {
                showErrorAlert(error.localizedDescription)
            }
            return
        }

        // AI retries have completed. A persistence failure never calls the analyzer again.
        let finalTitle = title.isEmpty ? result.title : title
        let scriptToSave = ScriptData(title: finalTitle, sentences: result.sentences)
        do {
            guard activeRequestID == requestID, !Task.isCancelled else { return }
            let script = try await databaseContainer.scriptManagementService.createScript(scriptData: scriptToSave)
            // An already-started transaction may commit after UI cancellation.
            guard activeRequestID == requestID, !Task.isCancelled else { return }
            if let scriptID = script.id {
                router.reset()
                router.push(Route.memorization(scriptId: scriptID, scriptTitle: finalTitle))
            }
        } catch {
            guard activeRequestID == requestID, !Task.isCancelled else { return }
            AppLog.database.error("스크립트 저장 실패")
            showErrorAlert("스크립트를 저장하는 데 실패했습니다.")
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
    AsyncPreview(operation: {
        try await DatabaseContainer.getForPreview(withMockData: true)
    }) { container in
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
            .environment(container)
            .environment(NavigationRouter())
        }
    }
}
