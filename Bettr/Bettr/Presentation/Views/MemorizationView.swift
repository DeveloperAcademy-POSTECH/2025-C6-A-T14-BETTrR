//
//  MemorizationView.swift
//  Bettr
//
//  Created by 길정수 on 10/29/25.
//

import SwiftUI


struct MemorizationView: View {
    let scriptData: ScriptData
    
    @State private var isChunkMode: Bool = false
    @State private var funcMode: FunctionMode = .hide
    @State private var langMode: LanguageMode = .engKor
    @State private var showWordList: Bool = false
    @State private var isPlaying: Bool = false
    @State private var showFeedbackModal: Bool = false
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 16) {
                    if isChunkMode {
                        // MARK: - 분할 모드
                        ForEach(scriptData.sentences, id: \.orderIndex) { sentence in
                            
                            // 1. 마지막 청크의 인덱스를 미리 찾아둡니다. (구분 기호용)
                            let lastChunkIndex = sentence.chunks.last?.orderIndex
                            
                            VStack(alignment: .leading, spacing: 8) {
                                // 2. 영어 청크 라인
                                CustomFlowLayout(spacing: 0) { // 청크 간 간격은 Text로 조절
                                    ForEach(sentence.chunks, id: \.orderIndex) { chunk in
                                        Text(chunk.englishText)
                                            .font(.system(size: 36))
                                            .padding(.vertical, 8)
                                            .padding(.horizontal, 10)
                                            .background(
                                                RoundedRectangle(cornerRadius: 2)
                                                    .fill(Color.primary.opacity(0.05))
                                            )
                                            .onTapGesture {
                                                // TODO: 여기에 클릭 시 동작 추가
                                                print("Tapped English: \(chunk.englishText)")
                                            }
                                        
                                        // 마지막 청크가 아니면 구분 기호 추가
                                        if chunk.orderIndex != lastChunkIndex {
                                            Text(" / ")
                                                .font(.system(size: 36))
                                                .foregroundColor(.gray.opacity(0.7))
                                                .padding(.horizontal, 2) // 구분 기호 좌우 살짝 띄우기
                                        }
                                    }
                                }
                                
                                // 3. 한국어 청크 라인
                                CustomFlowLayout(spacing: 0) {
                                    ForEach(sentence.chunks, id: \.orderIndex) { chunk in
                                        Text(chunk.koreanText)
                                            .font(.system(size: 20))
                                            .padding(.vertical, 5)
                                            .padding(.horizontal, 8)
                                            .background(
                                                RoundedRectangle(cornerRadius: 2)
                                                    .fill(Color.primary.opacity(0.05))
                                            )
                                            .onTapGesture {
                                                // TODO: 여기에 클릭 시 동작 추가
                                                print("Tapped Korean: \(chunk.koreanText)")
                                            }
                                        
                                        // 마지막 청크가 아니면 구분 기호 추가
                                        if chunk.orderIndex != lastChunkIndex {
                                            Text(" / ")
                                                .font(.system(size: 20))
                                                .foregroundColor(.gray.opacity(0.7))
                                                .padding(.horizontal, 2)
                                        }
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    } else {
                        // MARK: - 전체 모드
                        ForEach(scriptData.sentences, id: \.orderIndex) { sentence in
                            VStack(alignment: .leading, spacing: 8) {
                                // 1. 영어 텍스트
                                Text(sentence.englishText)
                                    .font(.system(size: 36))
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(Color.primary.opacity(0.05))
                                    )
                                
                                // 2. 한국어 텍스트
                                Text(sentence.koreanText)
                                    .font(.system(size: 20))
                                    .padding(.vertical, 5)
                                    .padding(.horizontal, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(Color.primary.opacity(0.05))
                                    )
                            }
                            .frame(maxWidth: .infinity, alignment: .leading) // 왼쪽 정렬
                        }
                    }
                }
                .padding(.horizontal, 60)
                .padding(.vertical, 40)
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
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.easeInOut, value: showWordList)
        .memorizationToolbar(
            title: scriptData.title,
            isChunkMode: $isChunkMode,
            functionMode: $funcMode,
            languageMode: $langMode,
            isWordListOpen: $showWordList,
            isPlaying: $isPlaying,
            isFeedbackModalOpen: $showFeedbackModal
        )
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showFeedbackModal) {
            RecordingView(sentences: [
                "I'm testing now.", "This is Test."
            ])
        }
    }
}
