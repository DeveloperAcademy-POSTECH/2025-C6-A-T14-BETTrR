import SwiftUI

struct EmptyScriptsView: View {
    let onSelectPhoto: () -> Void
    let onTakePhoto: () -> Void
    let onSelectFile: () -> Void
    
    var body: some View {
        VStack(spacing: 36) {
            VStack(spacing: 16) {
                //TODO: 아이콘 바뀌면 크기도 같이 조정
                FolderIconView(width: 221, height: 178)
                GuidanceTextView()
            }
            
            AddButtonView(
                onSelectPhoto: onSelectPhoto, onTakePhoto: onTakePhoto, onSelectFile: onSelectFile
            )
        }
        .padding(.top, 52) // 위 아래 2 : 3 비율을 유지하기 위해 AddButtonView bottom 패딩 값의 2/3을 위로 보상
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
            Text("암기하고 싶은 스크립트를 등록하고,")
                .font(.calloutRegular16)
                .foregroundColor(.normalGray600)
            
            Text("학습을 시작해 보세요.")
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
    
    var body: some View {
        Button("스크립트 등록") {
        }
        .buttonStyle(.general)
        .padding(.bottom, 78) // 아래에 공간이 있어야 Menu가 아래로 열림
        .overlay {
            AddScriptMenuView(onSelectPhoto: onSelectPhoto, onTakePhoto: onTakePhoto, onSelectFile: onSelectFile)
        }
    }
}
