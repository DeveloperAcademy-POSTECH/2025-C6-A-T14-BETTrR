import SwiftUI
import PhotosUI

struct HomeView: View {
    @Environment(NavigationRouter.self) var router
    @Environment(DatabaseContainer.self) var container
    
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var showingPhotoPicker = false
    @State private var isShowingCamera = false
    @State private var isShowingDocumentPicker = false
    @State private var scriptToDelete: Script? = nil
    @State private var showingDeleteConfirm = false
    @State private var showingFileErrorAlert = false
    @State private var fileErrorMessage = ""
    
    private let textRecognitionService = TextRecognitionService()
    private let pdfTextExtractor = PDFTextExtractor()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 84) {
            MainHeaderView()
                .padding(.top, 48)
            
            HomeContentView(
                onSelectPhoto: { showingPhotoPicker = true },
                onTakePhoto: { isShowingCamera = true },
                onSelectFile: { isShowingDocumentPicker = true },
                requestDelete: requestDelete
            )
        }
        .task {
            do {
                try await container.refreshScripts()
            } catch {
                print("Failed to refresh scripts: \(error)")
            }
        }
        .photosPicker(isPresented: $showingPhotoPicker, selection: $selectedPhoto, matching: .images)
        .fullScreenCover(isPresented: $isShowingCamera) {
            ImagePicker(sourceType: .camera) { image in
                process(image: image, title: "새로운 사진")
            }
            .ignoresSafeArea()
        }
        .fileImporter(isPresented: $isShowingDocumentPicker, allowedContentTypes: [.pdf]) { result in
            switch result {
            case .success(let url):
                let title = url.deletingPathExtension().lastPathComponent
                if let text = pdfTextExtractor.extractText(from: url) {
                    router.push(Route.scriptConfirm(initialText: text, initialTitle: title))
                } else {
                    showFileError(message: "PDF 파일에서 텍스트를 추출할 수 없습니다.")
                }
            case .failure(let error):
                showFileError(message: "파일을 불러오는 데 실패했습니다: \(error.localizedDescription)")
            }
        }
        .onChange(of: selectedPhoto) { oldValue, newValue in
            guard let item = newValue else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    process(image: uiImage, title: "사진 보관함에서 가져온 스크립트")
                }
                
                selectedPhoto = nil
            }
        }
        .alert("스크립트를 삭제하시겠어요?", isPresented: $showingDeleteConfirm, presenting: scriptToDelete) { script in
            Button("삭제", role: .destructive) {
                deleteScript(script: script)
            }
            Button("취소", role: .cancel) {}
        } message: { script in
            Text("선택하신 스크립트 '\(script.title)'과 학습 기록은 복구할 수 없습니다.")
        }
        .alert("오류", isPresented: $showingFileErrorAlert) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(fileErrorMessage)
        }
    }
    
    private func showFileError(message: String) {
        fileErrorMessage = message
        showingFileErrorAlert = true
    }
    
    private func requestDelete(script: Script) {
        scriptToDelete = script
        showingDeleteConfirm = true
    }
    
    private func deleteScript(script: Script) {
        guard let id = script.id else { return }
        Task {
            do {
                try await container.scriptManagementService.deleteScript(id: id)
                try await container.refreshScripts()
            } catch {
                print("Failed to delete script: \(error)")
            }
        }
    }
    
    private func process(image: UIImage, title: String) {
        textRecognitionService.recognizeText(from: image) { text in
            router.push(Route.scriptConfirm(initialText: text, initialTitle: title))
        }
    }
}

#Preview("Empty Scripts") {
    AsyncPreview(operation: {
        try await DatabaseContainer.getForPreview(withMockData: false)
    }) { container in
        HomeView()
            .environment(container)
            .environment(NavigationRouter())
    }
}

#Preview("With Scripts") {
    AsyncPreview(operation: {
        try await DatabaseContainer.getForPreview(withMockData: true)
    }) { container in
        HomeView()
            .environment(container)
            .environment(NavigationRouter())
    }
}
