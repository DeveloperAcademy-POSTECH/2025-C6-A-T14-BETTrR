import SwiftUI
import PhotosUI

struct ScriptsSectionView: View {
    let scripts: [Script]
    
    @Environment(NavigationRouter.self) var router
    @Environment(DatabaseContainer.self) var container
    
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var showingPhotoPicker = false
    @State private var showingOptions = false
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
                    Button(action: { showingOptions = true }) {
                        VStack(alignment: .leading, spacing: 8) {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                                .foregroundColor(Color.gray.opacity(0.3))
                                .frame(width: 200, height: 150)
                                .overlay(
                                    Circle()
                                        .fill(Color.blue)
                                        .frame(width: 56, height: 56)
                                        .overlay(
                                            Image(systemName: "plus")
                                                .font(.system(size: 24, weight: .medium))
                                                .foregroundColor(.white)
                                        )
                                )
                            Text("새 스크립트 추가")
                                .font(.system(size: 15))
                                .lineLimit(2)
                                .frame(width: 200, alignment: .leading)
                                .foregroundColor(.primary)
                        }
                    }
                    .popover(isPresented: $showingOptions, attachmentAnchor: .point(.bottom)) {
                        VStack {
                            Button(action: {
                                showingOptions = false
                                showingPhotoPicker = true
                            }) {
                                Label("사진 보관함", systemImage: "photo")
                            }
                            .padding()
                            
                            Button(action: {}) {
                                Label("사진 찍기", systemImage: "camera")
                            }
                            .disabled(true)
                            .padding()
                            
                            Button(action: {}) {
                                Label("파일 선택", systemImage: "doc")
                            }
                            .disabled(true)
                            .padding()
                        }
                        .padding()
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
        .onChange(of: selectedPhoto) {
            oldValue,
            newValue in
            guard let item = newValue else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    textRecognitionService.recognizeText(from: uiImage) { text in
                        router.push(
                            Route.scriptInput(
                                initialText: text
                            )
                        )
                    }
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
}

// MARK: - Script Card Component

private struct ScriptCard: View {
    @Environment(NavigationRouter.self) var router
    
    let script: Script
    let onDelete: () -> Void
    
    var body: some View {
        Button(action: {
            if let scriptId = script.id {
                router.push(Route.memorization(scriptId: scriptId))
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
