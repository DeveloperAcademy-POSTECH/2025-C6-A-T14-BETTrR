import SwiftUI
import Lottie

struct ScriptConfirmLoadingView: View {
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 8) {
                Text("스크립트를 확인하고 있어요")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.primary)
                
                Text("더 나은 암기 환경을 위해 잠시만 기다려 주세요")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 36)
            .padding(.bottom, 60)
            
            LottieView(animation: .named("geminiAnalLottie"))
                .looping()
                .aspectRatio(contentMode: .fit)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

#Preview {
    ScriptConfirmLoadingView()
}
