//
//  WordLoadingView.swift
//  Bettr
//
//  Created by Isa on 11/12/25.
//

import SwiftUI

// MARK: - LoadingView (단어 로딩중일 때 뷰)
struct WordLoadingView: View {
    var body: some View {
        VStack(spacing: 36) {
            ProgressView()
                .frame(width: 30, height: 30)
                .foregroundStyle(.secondaryBlue700)
            
            VStack(spacing: 12) {
                Text("단어장을 불러오는 중입니다.")
                    .font(.iconBold20)
                    .foregroundStyle(.normalBlack900)
                
                Text("잠시 기다려주세요.")
                    .font(.calloutRegular16)
                    .foregroundStyle(.normalBlack900)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    WordLoadingView()
        .background(.gray.opacity(0.1))
}
