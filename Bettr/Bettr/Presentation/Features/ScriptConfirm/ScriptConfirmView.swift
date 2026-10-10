import SwiftUI

// MARK: - 화면 UI
@MainActor
struct ScriptConfirmView: View {
    @Environment(NavigationRouter.self) var router
    @Environment(\.dismiss) private var dismiss

    private static let maxCharacterCount = 2000

    @State private var viewModel: ScriptConfirmViewModel
    @State var scriptTitle: String
    @State var scriptContent: String
    @State private var isEditingContent = false
    @State private var isTitleEditing: Bool = false

    // TextEditor 포커스 상태 감지용 (버튼 제어)
    @FocusState private var isFocusedContentEditor: Bool

    @State private var showErrorAlert = false

    // 뒤로가기 확인 알림
    @State private var showBackAlert: Bool = false
    @State private var isVisible = false

    init(
        initialText: String?,
        initialTitle: String?,
        viewModel: ScriptConfirmViewModel
    ) {
        _viewModel = State(initialValue: viewModel)
        let content = initialText ?? ""

        // 처음부터 영어/숫자/기호만 남김 (OCR에서 한국어 들어와도 여기서 제거됨)
        let asciiFiltered = content.unicodeScalars.filter { $0.isASCII }
        let cleaned = String(String.UnicodeScalarView(asciiFiltered))
        _scriptContent = State(initialValue: String(cleaned.prefix(Self.maxCharacterCount)))
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
            .disabled(!viewModel.canEdit)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 8) {
                Button(action: startAnalysis) {
                    Text(viewModel.canRetrySaving ? "저장 다시 시도" : "분석 및 암기 시작")
                        .bold()
                }
                .buttonStyle(GeneralButtonStyle(width: 404))
                .frame(width: 404, height: 48)
                .disabled(!viewModel.canRetrySaving && (
                    !viewModel.canStartAnalysis || scriptContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ))

                if viewModel.canRetrySaving {
                    Button("내용 다시 편집", action: viewModel.resumeEditing)
                }
            }
            .padding(.bottom, 10)
        }
        .allowsHitTesting(!viewModel.isLoading)
        .accessibilityHidden(viewModel.isLoading)
        .overlay {
            if viewModel.isLoading {
                ScriptConfirmLoadingView(isSaving: viewModel.isSaving)
                    .ignoresSafeArea()
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
                .disabled(!viewModel.canEdit)
            }
        }
        .toolbar(viewModel.isLoading ? .hidden : .visible, for: .navigationBar)
        .alert("저장하지 않고 나가시겠어요?", isPresented: $showBackAlert) {
            Button("취소", role: .cancel) {}
            Button("나가기", role: .destructive) {
                viewModel.cancel()
                dismiss()
            }
        } message: {
            Text("이 화면의 편집 내용은 유지되지 않습니다. 이미 시작된 저장은 완료될 수 있습니다.")
        }
        .alert("오류", isPresented: $showErrorAlert) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .onChange(of: scriptContent) { _, newValue in
            if newValue.count > Self.maxCharacterCount {
                scriptContent = String(newValue.prefix(Self.maxCharacterCount))
            }
        }
        .onChange(of: viewModel.errorMessage) { _, message in showErrorAlert = message != nil }
        .onChange(of: viewModel.completion) { _, _ in showSavedScript() }
        .onChange(of: router.path) { _, _ in viewModel.cancel() }
        .onAppear { isVisible = true }
        .onDisappear {
            isVisible = false
            viewModel.cancel()
        }
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
        isTitleEditing = false
        isFocusedContentEditor = false
        let content = scriptContent
        let title = scriptTitle
        Task {
            guard isVisible else { return }
            if viewModel.canRetrySaving {
                await viewModel.retrySaving()
            } else {
                await viewModel.start(content: content, title: title)
            }
        }
    }

    private func showSavedScript() {
        guard let result = viewModel.consumeCompletion() else { return }
        router.reset()
        router.push(Route.memorization(scriptId: result.savedID, scriptTitle: result.title))
    }

}

#Preview {
    AsyncPreview(operation: {
        try await PreviewComposition.withDemoData()
    }) { composition in
        NavigationStack {
            composition.makeScriptConfirmView(initialText: """
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
            .environment(NavigationRouter())
        }
    }
}
