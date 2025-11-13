//
//  LoadingView.swift
//  Bettr
//
//  Created by 길정수 on 11/6/25.
//

import SwiftUI

struct LoadingView: View {
    let isLoading: Bool
    let errorMessage: String?
    
    var body: some View {
        if let errorMessage = errorMessage, !errorMessage.isEmpty {
            Text(errorMessage)
                .foregroundColor(.red)
        } else if isLoading {
            ProgressView()
        } else {
            Text("Error! Data Not Found")
        }
    }
}

import SwiftUI

struct ErrorView: View {
    let error: AppError
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            Text(error.userFriendlyMessage)
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // 1. "재시도"가 가능한 에러일 때만 버튼 표시
            if error.isRetryable {
                Button("다시 시도") {
                    onRetry()
                }
                .buttonStyle(.borderedProminent)
            }
            
            // 2. "권한" 에러일 때만 버튼 표시
            if case .permissionDenied = error {
                Button("설정으로 이동") {
                    // 👈 여기에 설정 화면 여는 로직 추가
                    // (예: UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!))
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}
