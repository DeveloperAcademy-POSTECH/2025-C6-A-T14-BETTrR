import SwiftUI

struct AddScriptMenuView: View {
    let onSelectPhoto: () -> Void
    let onTakePhoto: () -> Void
    let onSelectFile: () -> Void
    
    var body: some View {
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
