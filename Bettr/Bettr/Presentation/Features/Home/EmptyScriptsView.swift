import SwiftUI

struct EmptyScriptsView: View {
    let onSelectPhoto: () -> Void
    let onTakePhoto: () -> Void
    let onSelectFile: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // 폴더 아이콘
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 80))
                .foregroundColor(.gray.opacity(0.5))
            
            // 안내 텍스트
            VStack(spacing: 8) {
                Text("추가 버튼 혹은 드래그 앤 드롭으로")
                    .font(.body)
                    .foregroundColor(.secondary)
                
                Text("파일을 추가해주세요.")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            // 스크립트 추가 메뉴
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
                Text("스크립트 추가")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(25)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    EmptyScriptsView(onSelectPhoto: { print("Select photo") }, onTakePhoto: { print("Take photo") }, onSelectFile: { print("Select file") })
}