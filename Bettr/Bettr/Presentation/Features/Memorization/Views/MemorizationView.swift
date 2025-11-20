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
    @State private var modalRouter = NavigationRouter()
    
    @Environment(AudioPlaybackService.self) private var audioService
    @Environment(DatabaseContainer.self) private var container
    
    init(viewModel: MemorizationViewModel, wordListViewModel: WordListViewModel) {
        _viewModel = State(initialValue: viewModel)
        _wordListViewModel = State(initialValue: wordListViewModel)
    }
    
    var body: some View {
        ZStack {
            
            contentView
            
            // 단어장 뷰
            if viewModel.uiState.showWordList {
                WordListOverlay(
                    showWordList: $viewModel.uiState.showWordList,
                    viewModel: wordListViewModel
                )
            }
            
            toasterOverlay
        }
        .onTapGesture {
            viewModel.endTitleEditing()
        }
        .animation(.easeInOut, value: viewModel.uiState.showWordList)
        .onChange(of: audioService.isPlaying) { _, serviceIsPlaying in
            viewModel.handleAudioServiceStateChange(
                isPlaying: serviceIsPlaying,
                isPaused: audioService.isPaused
            )
        }
        .onDisappear {
            viewModel.onDisappear()
        }
        .toolbar {
            MemorizationToolbarContent(viewModel: viewModel, showEditIcon: true)
        }
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $viewModel.uiState.showFeedbackModal) {
            FeedbackHistoryView(
                viewModel: FeedbackHistoryViewModel(
                    scriptId: viewModel.scriptId,
                    scriptService: container.scriptManagementService
                )
            )
            .environment(modalRouter)
        }
        .onAppear {
            viewModel.onAppear()
            
            Task {
                await wordListViewModel.loadWords()
            }
        }
        .animation(.spring(), value: viewModel.uiState.toasterMessage)
    }
    
    /// 메인 콘텐츠 뷰
    @ViewBuilder
    private var contentView: some View {
        if viewModel.isLoadingScript { // 로딩
            ProgressView()
        } else if let error = viewModel.currentError { // 에러
            ErrorView(error: error) {
                Task { // 다시 시도
                    await viewModel.loadScriptById()
                }
            }
        } else if viewModel.scriptData != nil { // 성공
            successView
        } else { // 예외 케이스: 로딩도 아니고, 에러도 아닌데, 데이터도 없는 경우
            ErrorView(error: .unknown("데이터를 불러오지 못했습니다.")) {
                Task {
                    await viewModel.loadScriptById()
                }
            }
        }
    }
    
    /// 성공 뷰
    private var successView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 24) {
                    if viewModel.uiState.isChunkMode {
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
            .onChange(of: audioService.currentPlayingSentenceIndex) { _, newIndex in
                if let newIndex {
                    withAnimation {
                        proxy.scrollTo(newIndex, anchor: .top)
                    }
                }
            }
        }
    }
    
    /// 토스터 오버레이 뷰
    @ViewBuilder
    private var toasterOverlay: some View {
        VStack {
            Spacer()
            
            if let message = viewModel.uiState.toasterMessage {
                ToasterView(message: message)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .allowsHitTesting(viewModel.uiState.toasterMessage != nil)
    }
}
