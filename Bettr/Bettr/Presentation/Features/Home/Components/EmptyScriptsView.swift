import SwiftUI

struct EmptyScriptsView: View {
    let onSelectPhoto: () -> Void
    let onTakePhoto: () -> Void
    let onSelectFile: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            FolderIconView()
            GuidanceTextView()
            AddButtonView(
                onSelectPhoto: onSelectPhoto,
                onTakePhoto: onTakePhoto,
                onSelectFile: onSelectFile
            )
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct FolderIconView: View {
    var body: some View {
        Image(systemName: "folder.badge.plus")
            .font(.system(size: 80))
            .foregroundColor(.gray.opacity(0.5))
    }
}

private struct GuidanceTextView: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("추가 버튼 혹은 드래그 앤 드롭으로")
                .font(.body)
                .foregroundColor(.secondary)
            
            Text("파일을 추가해주세요.")
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
}

private struct AddButtonView: View {
    let onSelectPhoto: () -> Void
    let onTakePhoto: () -> Void
    let onSelectFile: () -> Void
    
    var body: some View {
        Text("스크립트 추가")
            .font(.headline)
            .foregroundColor(.white)
            .padding(.horizontal, 32)
            .padding(.vertical, 12)
            .background(Color.blue)
            .cornerRadius(25)
            .glassEffect()
            .overlay {
                AddScriptMenuView(
                    onSelectPhoto: onSelectPhoto,
                    onTakePhoto: onTakePhoto,
                    onSelectFile: onSelectFile
                )
            }
    }
}

#Preview {
    EmptyScriptsView(
        onSelectPhoto: { print("Select photo") },
        onTakePhoto: { print("Take photo") },
        onSelectFile: { print("Select file") }
    )
}
