//
//  MemorizationView.swift
//  Bettr
//
//  Created by 길정수 on 10/29/25.
//

import SwiftUI


struct MemorizationView: View {
    let scriptData: ScriptData
    
    /// 툴바에 있는 버튼을 위한 변수
    @State private var isChunkMode: Bool = false
    @State private var funcMode: FunctionMode = .hide
    @State private var langMode: LanguageMode = .engKor
    @State private var showWordList: Bool = false
    @State private var isPlaying: Bool = false
    @State private var showFeedbackModal: Bool = false
    
    /// 숨김 상태 추적용 @State 변수
    @State private var hiddenEngChunks: Set<Int> = []
    @State private var hiddenKorChunks: Set<Int> = []
    @State private var hiddenEngSentences: Set<Int> = []
    @State private var hiddenKorSentences: Set<Int> = []
    
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
                                        
                                        // 현재 숨김 상태인지 확인하는 변수
                                        let isEngChunkHidden = hiddenEngChunks.contains(chunk.orderIndex)
                                        
                                        Text(chunk.englishText)
                                            .font(.system(size: 36))
                                            .padding(.vertical, 8)
                                            .padding(.horizontal, 5)
                                            .opacity(isEngChunkHidden ? 0 : 1) // 텍스트 투명도
                                            .background(
                                                RoundedRectangle(cornerRadius: 2)
                                                    .fill(isEngChunkHidden ? Color.primary.opacity(0.05) : Color.clear)
                                            )
                                            .onTapGesture {
                                                // 가리기 모드
                                                if funcMode == .hide  {
                                                    withAnimation(.easeInOut(duration: 0.02)) {
                                                        if isEngChunkHidden {
                                                            hiddenEngChunks.remove(chunk.orderIndex)
                                                        } else {
                                                            hiddenEngChunks.insert(chunk.orderIndex)
                                                        }
                                                    }
                                                } else { // 재생모드
                                                    print("재생모드!")
                                                }
                                            }
                                        
                                        // 마지막 청크가 아니면 구분 기호 추가
                                        if chunk.orderIndex != lastChunkIndex {
                                            Text(" / ")
                                                .font(.system(size: 36))
                                                .foregroundColor(.gray.opacity(0.7))
                                        }
                                    }
                                }
                                
                                // 3. 한국어 청크 라인
                                CustomFlowLayout(spacing: 0) {
                                    ForEach(sentence.chunks, id: \.orderIndex) { chunk in
                                        // 현재 숨김 상태인지 확인하는 변수
                                        let isKorChunkHidden = hiddenKorChunks.contains(chunk.orderIndex)
                                        
                                        Text(chunk.koreanText)
                                            .font(.system(size: 20))
                                            .padding(.vertical, 5)
                                            .padding(.horizontal, 4)
                                            .opacity(isKorChunkHidden ? 0 : 1)
                                            .background(
                                                RoundedRectangle(cornerRadius: 2)
                                                    .fill(isKorChunkHidden ? Color.primary.opacity(0.05) : Color.clear)
                                            )
                                            .onTapGesture {
                                                // 가리기 모드
                                                if funcMode == .hide  {
                                                    withAnimation(.easeInOut(duration: 0.02)) {
                                                        if isKorChunkHidden {
                                                            hiddenKorChunks.remove(chunk.orderIndex)
                                                        } else {
                                                            hiddenKorChunks.insert(chunk.orderIndex)
                                                        }
                                                    }
                                                } else { // 재생모드
                                                    print("재생모드!")
                                                }
                                            }
                                        
                                        // 마지막 청크가 아니면 구분 기호 추가
                                        if chunk.orderIndex != lastChunkIndex {
                                            Text(" / ")
                                                .font(.system(size: 20))
                                                .foregroundColor(.gray.opacity(0.7))
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
                                // 현재 숨김 상태인지 확인하는 변수
                                let isEngSentenceHidden = hiddenEngSentences.contains(sentence.orderIndex)
                                
                                // 1. 영어 텍스트
                                Text(sentence.englishText)
                                    .font(.system(size: 36))
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 10)
                                    .opacity(isEngSentenceHidden ? 0 : 1)
                                    .background(
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(isEngSentenceHidden ? Color.primary.opacity(0.05) : Color.clear)
                                    )
                                    .onTapGesture {
                                        // 가리기 모드
                                        if funcMode == .hide  {
                                            withAnimation(.easeInOut(duration: 0.02)) {
                                                if isEngSentenceHidden {
                                                    hiddenEngSentences.remove(sentence.orderIndex)
                                                } else {
                                                    hiddenEngSentences.insert(sentence.orderIndex)
                                                }
                                            }
                                        } else { // 재생모드
                                            print("재생모드!")
                                        }
                                    }
                                
                                // 현재 숨김 상태인지 확인하는 변수
                                let isKorSentenceHidden = hiddenKorSentences.contains(sentence.orderIndex)
                                
                                // 2. 한국어 텍스트
                                Text(sentence.koreanText)
                                    .font(.system(size: 20))
                                    .padding(.vertical, 5)
                                    .padding(.horizontal, 8)
                                    .opacity(isKorSentenceHidden ? 0 : 1)
                                    .background(
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(isKorSentenceHidden ? Color.primary.opacity(0.05) : Color.clear)
                                    )
                                    .onTapGesture {
                                        // 가리기 모드
                                        if funcMode == .hide  {
                                            withAnimation(.easeInOut(duration: 0.02)) {
                                                if isKorSentenceHidden {
                                                    hiddenKorSentences.remove(sentence.orderIndex)
                                                } else {
                                                    hiddenKorSentences.insert(sentence.orderIndex)
                                                }
                                            }
                                        } else { // 재생보드
                                            print("재생모드!")
                                        }
                                    }
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
