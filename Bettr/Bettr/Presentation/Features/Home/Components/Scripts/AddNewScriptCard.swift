import SwiftUI
import PhotosUI

struct AddNewScriptCard: View {
    let onSelectPhoto: () -> Void
    let onTakePhoto: () -> Void
    let onSelectFile: () -> Void
    
    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .inset(by: 1)
            .stroke(.primaryBlue200, style: StrokeStyle(lineWidth: 2, dash: [8, 8]))
            .aspectRatio(224/200, contentMode: .fit)
            .frame(maxWidth: .infinity)
            .overlay {
                Circle()
                    .fill(.primaryBlue500)
                    .frame(width: 48, height: 48)
                    .overlay {
                        Image(systemName: "plus")
                            .font(.labelBold16)
                            .foregroundStyle(.defaultWhite50)
                    }
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
}

#Preview {
    AddNewScriptCard(onSelectPhoto: {}, onTakePhoto: {}, onSelectFile: {})
        .padding()
}
