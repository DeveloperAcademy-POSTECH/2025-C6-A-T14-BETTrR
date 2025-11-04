//
//  MemorizationView.swift
//  Bettr
//
//  Created by 길정수 on 10/29/25.
//
import SwiftUI

struct MemorizationView: View {
    @State var viewModel: MemorizationViewModel
    @Environment(AudioPlaybackService.self) private var audioService
    
    init(viewModel: MemorizationViewModel) {
            _viewModel = State(initialValue: viewModel)
    }
    
    var body: some View {
        ZStack {
            if viewModel.scriptData != nil {
                ScrollView {
                    VStack(spacing: 16) {
                        if viewModel.isChunkMode {
                            ChunkModeView(viewModel: viewModel)
                        } else {
                            SentenceModeView(viewModel: viewModel)
                        }
                    }
                    .padding(.horizontal, 60)
                    .padding(.vertical, 40)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
            } else {
                // 로딩, 에러 뷰
                ScriptLoadingView(
                    isLoading: !viewModel.showingError,
                    errorMessage: viewModel.errorMessage
                )
            }
            
            // 단어장 뷰
            if viewModel.showWordList {
                WordListOverlay(showWordList: $viewModel.showWordList, scriptId: viewModel.scriptId)
            }
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
            title: viewModel.toolbarTitle,
            isChunkMode: $viewModel.isChunkMode,
            functionMode: $viewModel.funcMode,
            languageMode: $viewModel.langMode,
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
                sentences: viewModel.referenceSentences
            )
        }
        .onAppear {
            viewModel.onAppear()
        }
    }
}
