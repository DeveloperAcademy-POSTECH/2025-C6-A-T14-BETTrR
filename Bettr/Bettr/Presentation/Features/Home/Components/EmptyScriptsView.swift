import SwiftUI

struct EmptyScriptsView: View {
    let onSelectPhoto: () -> Void
    let onTakePhoto: () -> Void
    let onSelectFile: () -> Void
    
    @Binding var showMenu: Bool
    
    var body: some View {
        VStack(spacing: 36) {
            VStack(spacing: 16) {
                //TODO: 아이콘 바뀌면 크기도 같이 조정
                FolderIconView(width: 221, height: 178)
                GuidanceTextView()
            }
            
            AddButtonView(
                onSelectPhoto: onSelectPhoto,
                onTakePhoto: onTakePhoto,
                onSelectFile: onSelectFile,
                showMenu: $showMenu
            )
        }
    }
}

private struct FolderIconView: View {
    let width: CGFloat
    let height: CGFloat
    
    var body: some View {
        Image(systemName: "arrow.up.folder")
            .resizable()
            .scaledToFit()
            .frame(width: width, height: height)
            .foregroundColor(.normalGray600)
    }
}

private struct GuidanceTextView: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("추가 버튼을 눌러")
                .font(.calloutRegular16)
                .foregroundColor(.normalGray600)
            
            Text("연습할 스크립트 파일을 추가해주세요.")
                .font(.calloutRegular16)
                .foregroundColor(.normalGray600)
        }
        .padding(.vertical, 16)
    }
}

private struct AddButtonView: View {
    let onSelectPhoto: () -> Void
    let onTakePhoto: () -> Void
    let onSelectFile: () -> Void
    
    @Binding var showMenu: Bool
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3)) {
                showMenu.toggle()
            }
        }) {
            Text("스크립트 추가")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 12)
                .background(Color.blue)
                .cornerRadius(25)
        }
        .overlay(alignment: .top) {
            if showMenu {
                AddScriptMenu(
                    onSelectPhoto: onSelectPhoto,
                    onTakePhoto: onTakePhoto,
                    onSelectFile: onSelectFile,
                    showMenu: $showMenu
                )
            }
        }
    }
}

#Preview {
    EmptyScriptsView(
        onSelectPhoto: { print("Select photo") },
        onTakePhoto: { print("Take photo") },
        onSelectFile: { print("Select file") },
        showMenu: .constant(false)
    )
}
