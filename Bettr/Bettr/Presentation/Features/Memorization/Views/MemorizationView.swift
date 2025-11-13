//
//  MemorizationView.swift
//  Bettr
//
//  Created by 길정수 on 10/29/25.
//
import SwiftUI

struct MemorizationView: View {
    
    @State var viewModel: MemorizationViewModel
    @State var wordListViewModel: WordListViewModel
    
    @Environment(AudioPlaybackService.self) private var audioService
    @State private var isTitleEditing: Bool = false
    
    init(viewModel: MemorizationViewModel, wordListViewModel: WordListViewModel) {
        _viewModel = State(initialValue: viewModel)
        _wordListViewModel = State(initialValue: wordListViewModel)
    }
    
    var body: some View {
        ZStack {
            // 로딩 중
            if viewModel.isLoadingScript {
                ProgressView()
            } else if let error = viewModel.currentError { // 에러
                ErrorView(error: error) {
                    Task { // 다시 시도
                        await viewModel.loadScriptById()
                    }
                }
            } else if viewModel.scriptData != nil { // 성공
                ScrollView {
                    VStack(spacing: 24) {
                        if viewModel.isChunkMode {
                            ChunkModeView(viewModel: viewModel)
                        } else {
                            SentenceModeView(viewModel: viewModel)
                        }
                    }
                    .padding(.horizontal, 80)
                    .padding(.top, 36)
                    .padding(.bottom, 48)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else { // 예외 케이스: 로딩도 아니고, 에러도 아닌데, 데이터도 없는 경우
                ErrorView(error: .unknown("데이터를 불러오지 못했습니다.")) {
                    Task {
                        await viewModel.loadScriptById()
                    }
                }
            }
            
            // 단어장 뷰
            if viewModel.showWordList {
                WordListOverlay(
                    showWordList: $viewModel.showWordList,
                    viewModel: wordListViewModel
                )
            }
        }
        .onTapGesture {
            isTitleEditing = false
        }
        .animation(.easeInOut, value: viewModel.showWordList)
        .onChange(of: audioService.isPlaying) { _, serviceIsPlaying in
            viewModel.handleAudioServiceStateChange(
                isPlaying: serviceIsPlaying,
                isPaused: audioService.isPaused
            )
        }
        .onDisappear {
            viewModel.onDisappear()
        }
        .memorizationToolbar(
            title: $viewModel.currentTitle,
            showEditIcon: true,
            isTitleEditing: $isTitleEditing,
            isChunkMode: $viewModel.isChunkMode,
            functionMode: $viewModel.funcMode,
            isKoreanVisible: $viewModel.isKoreanVisible,
            isWordListOpen: $viewModel.showWordList,
            isPlaying: $viewModel.isPlaying,
            isPause: $viewModel.isPause,
            isFeedbackModalOpen: $viewModel.showFeedbackModal,
            isRecordingDisabled: viewModel.isRecordingDisabled
        )
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $viewModel.showFeedbackModal) {
            RecordingView(
                scriptId: viewModel.scriptId,
                sentences: viewModel.referenceSentences,
                scriptTitle: viewModel.currentTitle,
                currentFeedbackCount: viewModel.currentFeedbackCount
            )
        }
        .onAppear {
            viewModel.onAppear()
            
            Task {
                await wordListViewModel.loadWords()
            }
        }
    }
}
