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
    
    // 4-column grid layout
    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 50),
        GridItem(.flexible(), spacing: 50),
        GridItem(.flexible(), spacing: 50),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Scripts")
                    .font(.system(size: 25, weight: .semibold))
                    .padding(.horizontal, 20)
                
                VStack {
                    LazyVGrid(columns: columns, spacing: 20) {                                    AddNewScriptCard(
                        onSelectPhoto: { showingPhotoPicker = true },
                        onTakePhoto: { isShowingCamera = true },
                        onSelectFile: { isShowingDocumentPicker = true }
                    )
                        
                        ForEach(container.scripts) { script in
                            ScriptCard(script: script, onDelete: {
                                requestDelete(script: script)
                            })
                        }
                    }
                }                .padding(30)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(16)
                    .padding(.horizontal, 40)
            }
            .padding(.vertical)
        }
        .onAppear {
            container.refreshScripts()
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
        .alert("스크립트 삭제", isPresented: $showingDeleteConfirm, presenting: scriptToDelete) { script in
            Button("삭제", role: .destructive) {
                deleteScript(script: script)
            }
            Button("취소", role: .cancel) {}
        } message: { script in
            Text("'\(script.title)' 스크립트를 정말 삭제하시겠습니까? 이 동작은 되돌릴 수 없습니다.")
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
        do {
            try container.scriptManagementService.deleteScript(id: id)
            container.refreshScripts()
        } catch {
            print("Failed to delete script: \(error)")
        }
    }
    
    private func process(image: UIImage, title: String) {
        textRecognitionService.recognizeText(from: image) { text in
            router.push(Route.scriptConfirm(initialText: text, initialTitle: title))
        }
    }
}

// MARK: - AddNewScriptCard Component
private struct AddNewScriptCard: View {
    let onSelectPhoto: () -> Void
    let onTakePhoto: () -> Void
    let onSelectFile: () -> Void
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .stroke(style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                .foregroundColor(Color.gray.opacity(0.3))
            
            Circle()
                .fill(Color.blue)
                .frame(width: 56, height: 56)
                .overlay(
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                )
        }
        .aspectRatio(1, contentMode: .fit)
        .contentShape(Rectangle())
        .overlay {
            Menu {
                Button(action: onSelectPhoto) {
                    Label("사진 보관함", systemImage: "photo")
                }
                Button(action: onTakePhoto) {
                    Label("사진 찍기", systemImage: "camera")
                }
                Button(action: onSelectFile) {
                    Label("파일 선택", systemImage: "doc")
                }
            } label: {
                Color.clear
            }
        }
    }
}

// MARK: - ScriptCard Component
private struct ScriptCard: View {
    @Environment(NavigationRouter.self) var router
    
    let script: Script
    let onDelete: () -> Void
    
    var body: some View {
        Button(action: {
            if let scriptId = script.id {
                router.push(Route.scriptDashboard(scriptId: scriptId))
            }
        }) {
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.2))
                    .aspectRatio(1, contentMode: .fit)
                
                Text(script.title)
                    .foregroundStyle(Color.primary)
                    .font(.caption2)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label("삭제", systemImage: "trash")
            }
        }
    }
}

#Preview {
    HomeView()
        .environment(DatabaseContainer.getForPreview())
        .environment(NavigationRouter())
}
