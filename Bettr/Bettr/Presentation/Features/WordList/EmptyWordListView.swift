//
//  EmptyWordListView.swift
//  Bettr
//
//  Created by Isa on 11/12/25.
//

import SwiftUI

// MARK: - EmptyWordListView (단어 비었을 때 뷰)
struct EmptyWordListView: View {
    var body: some View {
        VStack(spacing: 36) {
            Image(systemName: "exclamationmark.triangle")
                .font(.bodyRegular24)
                .foregroundStyle(.normalBlack900)
            
            VStack(spacing: 12) {
                Text("단어장이 비어있어요!")
                    .font(.iconBold20)
                    .foregroundStyle(.normalBlack900)
                
                Text("추출된 단어가 없습니다.")
                    .font(.calloutRegular16)
                    .foregroundStyle(.normalBlack900)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    EmptyWordListView()
        .background(.gray.opacity(0.1))
}
