//
//  MemorizationView.swift
//  Bettr
//
//  Created by 길정수 on 10/29/25.
//

import SwiftUI
import AVFoundation

struct MemorizationView: View {
    
    let scriptId: Int64
    
    @Environment(DatabaseContainer.self) var container
    @Environment(AudioPlaybackService.self) private var audioService
    
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var scriptData: ScriptData?
    
    // 툴바에 있는 버튼을 위한 변수
    @State private var isChunkMode: Bool = false
    @State private var funcMode: FunctionMode = .hide
    @State private var langMode: LanguageMode = .engKor
    @State private var showWordList: Bool = false
    @State private var isPlaying: Bool = false
    @State private var isPause: Bool = false
    @State private var showFeedbackModal: Bool = false
    
    // 탭해서 재생시킨 텍스트를 저장하는 변수
    @State private var tappedPlaybackText: String? = nil
    
    // 청크 고유 식별자
    private struct ChunkIdentifier: Hashable {
        let sentenceIndex: Int
        let chunkIndex: Int
    }
    
    // 가리기 상태 추적용 @State 변수
    @State private var hiddenEngChunks: Set<ChunkIdentifier> = []
    @State private var hiddenKorChunks: Set<ChunkIdentifier> = []
    @State private var hiddenEngSentences: Set<Int> = []
    @State private var hiddenKorSentences: Set<Int> = []
    
    // 가리기 상태를 모두 초기화 하는 함수
    private func clearAllHiddenStates() {
        hiddenEngChunks.removeAll()
        hiddenKorChunks.removeAll()
        hiddenEngSentences.removeAll()
        hiddenKorSentences.removeAll()
    }
    
    // 아이디로 스크립트 정보를 가져오는 함수
    private func loadScriptById() {
        do {
            guard let fetchedData = try container.scriptManagementService.fetchScriptWithSentencesAndChunks(id: scriptId) else {
                // nil 반환 시 (스크립트 없음)
                errorMessage = "스크립트를 불러오는데 실패했습니다: \(scriptId)번 스크립트를 찾을 수 없습니다."
                showingError = true
                return
            }
            
            // 아래는 (Script, [(Sentence, [Chunk])]) 튜플을 ScriptData 뷰 모델로 변환하는 로직
            
            // 1. [(sentence: Sentence, chunks: [Chunk])] -> [SentenceData]
            let sentenceDataList: [SentenceData] = fetchedData.sentences.map { (sentence, chunks) in
                
                // 2. [Chunk] -> [ChunkData]
                // (DB의 Chunk 모델 속성을 ChunkData 뷰 모델 속성으로 매핑)
                let chunkDataList: [ChunkData] = chunks.map { chunk in
                    return ChunkData(
                        orderIndex: chunk.orderIndex,
                        englishText: chunk.englishText,
                        koreanText: chunk.koreanText
                    )
                }
                
                // 3. Sentence + [ChunkData] -> SentenceData
                return SentenceData(
                    orderIndex: sentence.orderIndex,
                    englishText: sentence.englishText,
                    koreanText: sentence.koreanText,
                    chunks: chunkDataList
                )
            }
            
            // 4. 최종 ScriptData 뷰 모델 생성
            let transformedScriptData = ScriptData(
                title: fetchedData.script.title,
                sentences: sentenceDataList
            )
            self.scriptData = transformedScriptData
            
        } catch {
            // try가 실패한 경우 (DB 에러 등)
            errorMessage = "스크립트 로딩 중 오류 발생: \(error.localizedDescription)"
            showingError = true
        }
    }
    
    var body: some View {
        // 스크립트 데이터가 없으면 피드백(녹음)을 할 수 없게 하기 위한 변수 선언
        let isRecordingDisabled = (scriptData == nil)
        
        ZStack {
            if let scriptData = scriptData {
                ScrollView {
                    VStack(spacing: 16) {
                        if isChunkMode {
                            // MARK: - 분할 모드
                            ForEach(scriptData.sentences, id: \.orderIndex) { sentence in
                                
                                // 1. 마지막 청크의 인덱스를 미리 찾아둡니다. (구분 기호용)
                                let lastChunkIndex = sentence.chunks.last?.orderIndex
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    // 2. 영어 청크 라인
                                    CustomFlowLayout(horizontalSpacing: 0, verticalSpacing: 5) {
                                        ForEach(sentence.chunks, id: \.orderIndex) { chunk in
                                            
                                            // 고유 ID 생성
                                            let chunkID = ChunkIdentifier(
                                                sentenceIndex: sentence.orderIndex,
                                                chunkIndex: chunk.orderIndex
                                            )
                                            
                                            // 고유 ID로 숨김 상태 확인
                                            let isEngChunkHidden = hiddenEngChunks.contains(chunkID)
                                            let isThisTapped = (tappedPlaybackText == chunk.englishText)
                                            
                                            Text(chunk.englishText)
                                                .font(.system(size: 30))
                                                .opacity(isEngChunkHidden ? 0 : 1) // 텍스트 투명도
                                                .background(
                                                    RoundedRectangle(cornerRadius: 2)
                                                        .fill(isEngChunkHidden ? Color.primary.opacity(0.05) : Color.clear)
                                                        .overlay(
                                                            RoundedRectangle(cornerRadius: 2)
                                                                .stroke(isThisTapped ? Color.primary : Color.clear, lineWidth: 1)
                                                        )
                                                )
                                                .onTapGesture {
                                                    // 가리기 모드
                                                    if funcMode == .hide  {
                                                        withAnimation(.easeInOut(duration: 0.02)) {
                                                            if isEngChunkHidden {
                                                                hiddenEngChunks.remove(chunkID)
                                                            } else {
                                                                hiddenEngChunks.insert(chunkID)
                                                            }
                                                        }
                                                    } else { // 재생모드
                                                        audioService.play(text: chunk.englishText)
                                                        tappedPlaybackText = chunk.englishText
                                                    }
                                                }
                                            
                                            // 마지막 청크가 아니면 구분 기호 추가
                                            if chunk.orderIndex != lastChunkIndex {
                                                Text(" / ")
                                                    .font(.system(size: 33))
                                                    .foregroundColor(.gray.opacity(0.7))
                                            }
                                        }
                                    }
                                    
                                    if langMode == .engKor {
                                        // 3. 한국어 청크 라인
                                        CustomFlowLayout(horizontalSpacing: 0, verticalSpacing: 5) {
                                            ForEach(sentence.chunks, id: \.orderIndex) { chunk in
                                                
                                                // 고유 ID 생성
                                                let chunkID = ChunkIdentifier(
                                                    sentenceIndex: sentence.orderIndex,
                                                    chunkIndex: chunk.orderIndex
                                                )
                                                
                                                // 고유 ID로 숨김 상태 확인
                                                let isKorChunkHidden = hiddenKorChunks.contains(chunkID)
                                                
                                                Text(chunk.koreanText)
                                                    .font(.system(size: 20))
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
                                                                    hiddenKorChunks.remove(chunkID)
                                                                } else {
                                                                    hiddenKorChunks.insert(chunkID)
                                                                }
                                                            }
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
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        } else {
                            // MARK: - 전체 모드
                            ForEach(scriptData.sentences, id: \.orderIndex) { sentence in
                                VStack(alignment: .leading, spacing: 12) {
                                    // 현재 숨김 상태인지 확인하는 변수
                                    let isEngSentenceHidden = hiddenEngSentences.contains(sentence.orderIndex)
                                    let isThisTapped = (tappedPlaybackText == sentence.englishText)
                                    
                                    // 1. 영어 텍스트
                                    Text(sentence.englishText)
                                        .font(.system(size: 30))
                                        .opacity(isEngSentenceHidden ? 0 : 1)
                                        .background(
                                            RoundedRectangle(cornerRadius: 2)
                                                .fill(isEngSentenceHidden ? Color.primary.opacity(0.05) : Color.clear)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 2)
                                                        .stroke(isThisTapped ? Color.primary : Color.clear, lineWidth: 1)
                                                )
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
                                                audioService.play(text: sentence.englishText)
                                                tappedPlaybackText = sentence.englishText
                                            }
                                        }
                                    
                                    // 현재 숨김 상태인지 확인하는 변수
                                    let isKorSentenceHidden = hiddenKorSentences.contains(sentence.orderIndex)
                                    
                                    if langMode == .engKor {
                                        
                                        // 2. 한국어 텍스트
                                        Text(sentence.koreanText)
                                            .font(.system(size: 20))
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
                                                }
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
            } else {
                // scriptData가 nil일 때 (로딩 중이거나 에러 발생 시)
                if showingError {
                    Text(errorMessage)
                        .foregroundColor(.red)
                } else {
                    ProgressView("스크립트 로딩 중...")
                }
            }
            
            // 단어장
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
        .onChange(of: funcMode) {
            if funcMode == .read {
                clearAllHiddenStates()
            }
            tappedPlaybackText = nil
        }
        .onChange(of: isChunkMode)  {
            clearAllHiddenStates()
            tappedPlaybackText = nil
        }
        .onChange(of: langMode)  {
            clearAllHiddenStates()
            tappedPlaybackText = nil
        }
        .onChange(of: isPlaying) { _, isNowPlaying in
            if isNowPlaying {
                // 재생
                guard let scriptData = scriptData else {
                    isPlaying = false // 데이터 없으면 다시 끔
                    return
                }
                audioService.playAll(sentences: scriptData.sentences)
                isPause = false // 재생 시작 시 '일시정지' 상태는 해제
                tappedPlaybackText = nil
            } else {
                // "정지" 버튼을 누름 (Playing/Paused -> Stopped)
                audioService.stop()
                tappedPlaybackText = nil
            }
        }
        .onChange(of: isPause) { _, isNowPaused in
            // isPlaying이 false(정지 상태)일 때는 이 토글이 작동하면 안 됨
            guard isPlaying else { return }
            
            if isNowPaused {
                // 일시정지
                audioService.pause()
            } else {
                // 이어하기
                audioService.resume()
            }
        }
        .onChange(of: audioService.isPlaying) { _, serviceIsPlaying in
            // 오디오서지스의 상태가 스스로 바꼈을 때 (ex. 재생이 끝났을 때)
            if !serviceIsPlaying && !audioService.isPaused {
                // 재생이 끝까지 완료됨
                isPlaying = false
                isPause = false
            }
        }
        .onDisappear {
            audioService.stop()
        }
        .memorizationToolbar(
            title: scriptData?.title ?? "Loading...",
            isChunkMode: $isChunkMode,
            functionMode: $funcMode,
            languageMode: $langMode,
            isWordListOpen: $showWordList,
            isPlaying: $isPlaying,
            isPause: $isPause,
            isFeedbackModalOpen: $showFeedbackModal,
            isRecordingDisabled: isRecordingDisabled
        )
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showFeedbackModal) { // 피드백 모달
            let referenceSentences = scriptData?.sentences.map { $0.englishText } ?? []
            RecordingView(sentences: referenceSentences)
        }
        .onAppear {
            loadScriptById()
        }
    }
}
