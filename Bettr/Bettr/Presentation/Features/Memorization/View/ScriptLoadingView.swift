//
//  ScriptLoadingView.swift
//  Bettr
//
//  Created by 길정수 on 11/3/25.
//

import SwiftUI

struct ScriptLoadingView: View {
    let isLoading: Bool
    let errorMessage: String?
    
    var body: some View {
        if let errorMessage = errorMessage, !errorMessage.isEmpty {
            Text(errorMessage)
                .foregroundColor(.red)
        } else if isLoading {
            ProgressView("스크립트 로딩 중...")
        } else {
            Text("스크립트 데이터가 없습니다.")
        }
    }
}
