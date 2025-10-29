//
//  MemorizationView.swift
//  Bettr
//
//  Created by 길정수 on 10/29/25.
//

import SwiftUI

struct MemorizationView: View {
    let title: String = "스크립트.pdf"
    
    @State private var isChunkMode: Bool = false
    @State private var funcMode: FunctionMode = .hide
    @State private var langMode: LanguageMode = .engKor
    @State private var showWordList: Bool = false
    @State private var isPlaying: Bool = false
    @State private var showFeedbackModal: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack {
                    if isChunkMode {
                        Text("청크모드")
                    } else {
                        Text("문장모드")
                    }
                    // 상태에 따라 다른 뷰를 표시
                    if funcMode == .hide {
                        Text("가리기 모드입니다.")
                    } else {
                        Text("재생 모드입니다.")
                    }
                    
                    if langMode == .engKor {
                        Text("한/영으로 봅니다.")
                    } else {
                        Text("영어만 봅니다.")
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                if showWordList {
                    Color.black.opacity(0.001) // 시각적으로는 안 보이지만 탭 감지 가능
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation {
                                showWordList = false
                            }
                        }
                    
                    HStack {
                        WordkListView()
                    }
                    .frame(maxWidth: .infinity, alignment: .topTrailing)
                    .padding(.trailing, 16)
                    .padding(.bottom, 13)
                    .padding(.top, -40)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            .animation(.easeInOut, value: showWordList)
            .memorizationToolbar(
                title: title,
                isChunkMode: $isChunkMode,
                functionMode: $funcMode,
                languageMode: $langMode,
                isWordListOpen: $showWordList,
                isPlaying: $isPlaying,
                isFeedbackModalOpen: $showFeedbackModal
            )
            .toolbarBackground(Color.blue, for: .navigationBar)
            .sheet(isPresented: $showFeedbackModal) {
                Text("피드백 모달")
            }
        }
    }
}

#Preview {
    MemorizationView()
}
