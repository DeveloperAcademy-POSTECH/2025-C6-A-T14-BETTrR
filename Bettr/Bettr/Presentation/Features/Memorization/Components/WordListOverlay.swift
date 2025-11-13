//
//  WordListOverlay.swift
//  Bettr
//
//  Created by 길정수 on 11/3/25.
//

import SwiftUI

struct WordListOverlay: View {
    @Binding var showWordList: Bool
    
    @State var viewModel: WordListViewModel
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.opacity(0.001)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation {
                        showWordList = false
                    }
                }
            
            WordkListView(
                scriptId: viewModel.scriptId,
                words: $viewModel.words,
                isLoading: $viewModel.isLoading
            )
            .padding(.top, 0)
            .padding(.trailing, 10)
            .padding(.bottom, 13)
            .transition(.move(edge: .trailing).combined(with: .opacity))
        }
    }
}
