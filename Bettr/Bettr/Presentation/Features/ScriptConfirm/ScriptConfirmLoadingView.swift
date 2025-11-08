import SwiftUI

struct ScriptConfirmLoadingView: View {
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Text("스크립트를 확인하고 있어요")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text("더 나은 암기 환경을 위해 잠시만 기다려 주세요")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
            }
            .padding(.top, 36)
            .padding(.bottom, 60)
            
            VStack(spacing: 16) {
                // 첫 번째 줄 (3개)
                HStack(spacing: 16) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 120)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 120)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 120)
                }
                
                // 두 번째 줄 (2개)
                HStack(spacing: 16) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 130)
                        .frame(maxWidth: .infinity)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 350, height: 130)
                }
                
                // 세 번째 줄 (2개)
                HStack(spacing: 16) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 120)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 120)
                }
                
                // 네 번째 줄 (2개)
                HStack(spacing: 16) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 300, height: 120)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 120)
                        .frame(maxWidth: .infinity)
                }
            }
            //            .padding(.horizontal, 40)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

#Preview {
    ScriptConfirmLoadingView()
}
