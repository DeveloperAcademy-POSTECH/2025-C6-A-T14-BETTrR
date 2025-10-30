//
//  MemorizationView.swift
//  Bettr
//
//  Created by 길정수 on 10/29/25.
//

import SwiftUI

//let mockScript: Script = {
//    
//    // --- 🧩 청크(Chunk) 데이터 ---
//    
//    // (문장 1의 청크들)
//    let chunk1_1 = Chunk(id: 101, sentenceId: 1, orderIndex: 0, englishText: "I am honored", koreanText: "저는 영광입니다")
//    let chunk1_2 = Chunk(id: 102, sentenceId: 1, orderIndex: 1, englishText: "to be with you today", koreanText: "오늘 여러분과 함께하게 되어")
//    
//    // (문장 2의 청크들)
//    let chunk2_1 = Chunk(id: 201, sentenceId: 2, orderIndex: 0, englishText: "I never graduated", koreanText: "저는 졸업하지 못했습니다")
//    let chunk2_2 = Chunk(id: 202, sentenceId: 2, orderIndex: 1, englishText: "from college.", koreanText: "대학을요.")
//    
//    // (문장 3의 청크들)
//    let chunk3_1 = Chunk(id: 301, sentenceId: 3, orderIndex: 0, englishText: "This is", koreanText: "이것은")
//    let chunk3_2 = Chunk(id: 302, sentenceId: 3, orderIndex: 1, englishText: "the story of my life.", koreanText: "제 인생 이야기입니다.")
//
//    // --- 📑 문장(Sentence) 데이터 ---
//
//    let sentence1 = Sentence(
//        id: 1, scriptId: 1,
//        orderIndex: 0,
//        englishText: "I am honored to be with you today.",
//        koreanText: "오늘 여러분과 함께하게 되어 영광입니다.",
//        chunks: [chunk1_1, chunk1_2] // 문장 1에 청크 1, 2 포함
//    )
//    
//    let sentence2 = Sentence(
//        id: 2,scriptId: 1,
//        orderIndex: 1,
//        englishText: "I never graduated from college.",
//        koreanText: "저는 대학을 졸업하지 못했습니다.",
//        chunks: [chunk2_1, chunk2_2] // 문장 2에 청크 1, 2 포함
//    )
//    
//    let sentence3 = Sentence(
//        id: 3,scriptId: 1,
//        orderIndex: 2,
//        englishText: "This is the story of my life.",
//        koreanText: "이것은 제 인생 이야기입니다.",
//        chunks: [chunk3_1, chunk3_2] // 문장 3에 청크 1, 2 포함
//    )
//
//    // --- 📜 스크립트(Script) 데이터 ---
//    
//    return Script(
//        id: 1,
//        title: "Steve Jobs' 2005 Stanford Speech",
//        createdAt: Date(),
//        lastPracticedAt: Date(),
//        sentences: [sentence1, sentence2, sentence3] // 스크립트에 3개의 문장 포함
//    )
//    
//}()

struct MemorizationView: View {
    let title: String
    
//    let script: Script
    
    @State private var isChunkMode: Bool = false
    @State private var funcMode: FunctionMode = .hide
    @State private var langMode: LanguageMode = .engKor
    @State private var showWordList: Bool = false
    @State private var isPlaying: Bool = false
    @State private var showFeedbackModal: Bool = false
    
    var body: some View {
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
        .fullScreenCover(isPresented: $showFeedbackModal) {
            RecordingView(sentences: [
                "I'm testing now.", "This is Test."
            ])
        }
    }
}
