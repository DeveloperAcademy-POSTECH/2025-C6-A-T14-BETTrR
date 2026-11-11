import SwiftUI
import PhotosUI

struct HomeView: View {
    @Environment(NavigationRouter.self) var router
    let model: HomeListModel
    let importModel: HomeImportModel
    
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var showingPhotoPicker = false
    @State private var isShowingCamera = false
    @State private var isShowingDocumentPicker = false
    @State private var scriptToDelete: Script? = nil
    @State private var showingDeleteConfirm = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            MainHeaderView()
                .padding(.top, 48)
                .padding(.horizontal, 84)
            
            HomeContentView(
                scripts: model.scripts,
                isLoading: model.isLoading,
                errorMessage: model.errorMessage,
                onRetry: { Task { await model.refresh() } },
                onSelectPhoto: { showingPhotoPicker = true },
                onTakePhoto: { isShowingCamera = true },
                onSelectFile: { isShowingDocumentPicker = true },
                requestDelete: requestDelete
            )
        }
        // 입력 처리 중에는 조작을 막아 진행 중인 선택이 조용히 대체되지 않게 합니다.
        .allowsHitTesting(!importModel.isProcessing)
        .overlay {
            if importModel.isProcessing {
                ZStack {
                    Color.normalBlack900.opacity(0.1)
                        .ignoresSafeArea()
                    VStack(spacing: 16) {
                        ProgressView()
                        // 로딩이 길어져도 사용자가 빠져나올 수 있어야 합니다.
                        Button("취소") { importModel.cancel() }
                    }
                }
            }
        }
        .task {
            await model.refresh()
        }
        .photosPicker(isPresented: $showingPhotoPicker, selection: $selectedPhoto, matching: .images)
        .fullScreenCover(isPresented: $isShowingCamera) {
            ImagePicker(sourceType: .camera) { image in
                importModel.importCameraImage(image)
            }
            .ignoresSafeArea()
        }
        .fileImporter(isPresented: $isShowingDocumentPicker, allowedContentTypes: [.pdf]) { result in
            importModel.importPDF(result)
        }
        .onChange(of: selectedPhoto) { _, newValue in
            guard let item = newValue else { return }
            selectedPhoto = nil
            importModel.importPhoto {
                guard let data = try await item.loadTransferable(type: Data.self) else { return nil }
                return UIImage(data: data)
            }
        }
        .onChange(of: importModel.completion) { _, _ in showImportedScript() }
        .onDisappear { importModel.cancel() }
        .alert("스크립트를 삭제하시겠어요?", isPresented: $showingDeleteConfirm, presenting: scriptToDelete) { script in
            Button("삭제", role: .destructive) {
                deleteScript(script: script)
            }
            .disabled(model.isDeleting)
            Button("취소", role: .cancel) {}
        } message: { script in
            Text("선택하신 스크립트 '\(script.title)'과 학습 기록은 복구할 수 없습니다.")
        }
        .alert("오류", isPresented: importErrorBinding) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(importModel.errorMessage ?? "")
        }
    }
    
    private var importErrorBinding: Binding<Bool> {
        Binding(
            get: { importModel.errorMessage != nil },
            set: { if !$0 { importModel.dismissError() } }
        )
    }
    
    private func requestDelete(script: Script) {
        scriptToDelete = script
        showingDeleteConfirm = true
    }
    
    private func deleteScript(script: Script) {
        guard let id = script.id else { return }
        Task {
            await model.deleteScript(id: id)
        }
    }
    
    private func showImportedScript() {
        guard let result = importModel.consumeCompletion() else { return }
        router.push(Route.scriptConfirm(initialText: result.text, initialTitle: result.title))
    }
}

#Preview("Empty Scripts") {
    AsyncPreview(operation: { try PreviewComposition.make() }) { composition in
        composition.makeHomeView(model: composition.makeHomeListModel(), importModel: composition.makeHomeImportModel())
            .environment(NavigationRouter())
    }
}

#Preview("With Scripts") {
    AsyncPreview(operation: { try await PreviewComposition.withDemoData() }) { composition in
        composition.makeHomeView(model: composition.makeHomeListModel(), importModel: composition.makeHomeImportModel())
            .environment(NavigationRouter())
    }
}
