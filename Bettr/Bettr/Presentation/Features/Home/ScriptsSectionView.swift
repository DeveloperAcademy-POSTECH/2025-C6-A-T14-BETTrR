import SwiftUI
import PhotosUI

struct ScriptsSectionView: View {
    let scripts: [Script]
    
    @Environment(NavigationRouter.self) var router
    @Environment(DatabaseContainer.self) var container
    
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var showingPhotoPicker = false
    @State private var isShowingCamera = false
    @State private var scriptToDelete: Script? = nil
    @State private var showingDeleteConfirm = false
    private let textRecognitionService = TextRecognitionService()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Scripts")
                    .font(.system(size: 25, weight: .semibold))
                
                Spacer()
                
                Button(action: {
                    // TODO: Navigate to all scripts
                }) {
                    HStack(spacing: 4) {
                        Text("더보기")
                            .font(.system(size: 15))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        // The complete visual look of the card
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                                .foregroundColor(Color.gray.opacity(0.3))
                            
                            // Visual-only plus button
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 56, height: 56)
                                .overlay(
                                    Image(systemName: "plus")
                                        .font(.system(size: 24, weight: .medium))
                                        .foregroundColor(.white)
                                )
                        }
                        .frame(width: 200, height: 150)
                        
                        Text("새 스크립트 추가")
                            .font(.system(size: 15))
                            .lineLimit(2)
                            .frame(width: 200, alignment: .leading)
                            .foregroundColor(.primary)
                    }
                    .overlay(alignment: .center) {
                        Menu {
                            Button(action: { showingPhotoPicker = true }) {
                                Label("사진 보관함", systemImage: "photo")
                            }
                            Button(action: { isShowingCamera = true }) {
                                Label("사진 찍기", systemImage: "camera")
                            }
                            Button(action: {}) {
                                Label("파일 선택", systemImage: "doc")
                            }.disabled(true)
                        } label: {
                            // The invisible tappable area for the menu
                            Color.clear
                                .frame(width: 56, height: 56)
                        }
                        .offset(y: -28) // Position the invisible menu trigger over the visual plus button
                    }
                    
                    // Script Cards
                    ForEach(scripts) { script in
                        ScriptCard(script: script, onDelete: {
                            requestDelete(script: script)
                        })
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .photosPicker(isPresented: $showingPhotoPicker, selection: $selectedPhoto, matching: .images)
        .fullScreenCover(isPresented: $isShowingCamera) {
            ImagePicker(sourceType: .camera) { image in
                process(image: image)
            }
            .ignoresSafeArea() // Correctly apply ignoresSafeArea to the SwiftUI view
        }
        .onChange(of: selectedPhoto) { oldValue, newValue in
            guard let item = newValue else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    process(image: uiImage)
                }
            }
        }
        .alert("스크립트 삭제", isPresented: $showingDeleteConfirm, presenting: scriptToDelete) { script in
            Button("삭제", role: .destructive) {
                deleteScript(script: script)
            }
            Button("취소", role: .cancel) {}
        } message: { script in
            Text("\'\(script.title)\' 스크립트를 정말 삭제하시겠습니까? 이 동작은 되돌릴 수 없습니다.")
        }
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
            // TODO: Handle error properly
            print("Failed to delete script: \(error)")
        }
    }
    
    private func process(image: UIImage) {
        textRecognitionService.recognizeText(from: image) { text in
            router.push(Route.scriptInput(initialText: text))
        }
    }
}

// MARK: - Script Card Component

private struct ScriptCard: View {
    @Environment(NavigationRouter.self) var router
    
    let script: Script
    let onDelete: () -> Void
    
    var body: some View {
        Button(action: {
            if let scriptId = script.id {
                router.push(Route.scriptDashboard(scriptId: scriptId))
            } else {
                // id가 nil인 경우
                print("Error: script.id가 nil이어서 네비게이션할 수 없습니다.")
            }
        }) {
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray)
                    .frame(width: 200, height: 150)
                
                Text(script.title)
                    .foregroundStyle(Color.primary)
                    .font(.system(size: 15))
                    .lineLimit(2)
                    .frame(width: 200, alignment: .leading)
                    .padding(.bottom, 8)
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
    let container = DatabaseContainer.getForPreview()
    
    return ScriptsSectionView(scripts: container.scripts)
        .environment(NavigationRouter())
        .environment(container)
}
