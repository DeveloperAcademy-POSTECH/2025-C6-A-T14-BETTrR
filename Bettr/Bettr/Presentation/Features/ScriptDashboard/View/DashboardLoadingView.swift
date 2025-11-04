//
//  DashboardLoadingView.swift
//  Bettr
//
//  Created by 길정수 on 11/4/25.
//

import SwiftUI

struct DashboardLoadingView: View {
    let isLoading: Bool
    let errorMessage: String?
    
    var body: some View {
        if let errorMessage = errorMessage, !errorMessage.isEmpty {
            Text(errorMessage)
                .foregroundColor(.red)
        } else if isLoading {
            ProgressView("대시보드 데이터 로딩 중...")
        } else {
            Text("대시보드 데이터가 없습니다.")
        }
    }
}
