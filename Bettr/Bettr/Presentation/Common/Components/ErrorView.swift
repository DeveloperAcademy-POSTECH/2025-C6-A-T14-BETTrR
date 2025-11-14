//
//  ErrorView.swift
//  Bettr
//
//  Created by 길정수 on 11/6/25.
//

import SwiftUI

struct ErrorView: View {
    let error: AppError
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            
            Spacer()
            
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.yellow)
            
            Text(error.userFriendlyMessage)
                .font(.calloutRegular20)
                .multilineTextAlignment(.center)
                .lineSpacing(10)
            
            // 1. "재시도"가 가능한 에러일 때만 버튼 표시
            if error.isRetryable {
                Button("다시 시도") {
                    onRetry()
                }
                .buttonStyle(.general)
            }
            
            // 2. "권한" 에러일 때만 버튼 표시
            if case .permissionDenied = error {
                Button("설정으로 이동") {
                    // 👈 여기에 설정 화면 여는 로직 추가
                    // (예: UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!))
                }
                .buttonStyle(.general)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Preview

#Preview("1. 재시도 가능 에러 (네트워크)") {
    ErrorView(error: .networkError("인터넷 연결을 확인해주세요.")) {
        // '다시 시도' 버튼 액션 (프리뷰에서는 비어있어도 됨)
        print("재시도 버튼 클릭됨")
    }
}

#Preview("2. 권한 에러") {
    ErrorView(error: .permissionDenied(type: "마이크")) {
        // '다시 시도' 버튼 액션 (이 케이스에선 호출되지 않음)
    }
}

#Preview("3. 재시도 불가 에러 (데이터 없음)") {
    ErrorView(error: .dataNotFound("해당 스크립트를 찾을 수 없습니다.")) {
        // '다시 시도' 버튼 액션 (이 케이스에선 버튼이 없음)
    }
}
