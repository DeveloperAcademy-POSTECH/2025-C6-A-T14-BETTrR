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
    @State private var wordLoadRequest = 0
    
    private let makeFeedbackHistory: @MainActor () -> FeedbackHistoryView

    private var audioService: any AudioPlaybackServiceProtocol {
        viewModel.audioService
    }
    
    init(
        viewModel: MemorizationViewModel,
        wordListViewModel: WordListViewModel,
        makeFeedbackHistory: @escaping @MainActor () -> FeedbackHistoryView
    ) {
        _viewModel = State(initialValue: viewModel)
        _wordListViewModel = State(initialValue: wordListViewModel)
        self.makeFeedbackHistory = makeFeedbackHistory
    }
    
    var body: some View {
        ZStack {
            contentView
            
            // 단어장 뷰
            if viewModel.uiState.showWordList {
                WordListOverlay(
                    showWordList: $viewModel.uiState.showWordList,
                    viewModel: wordListViewModel,
                    onRetry: { wordLoadRequest += 1 }
                )
            }
            
            // 토스터
            toasterOverlay
        }
        .onTapGesture {
            viewModel.endTitleEditing()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            MemorizationToolbar(viewModel: viewModel, showEditIcon: true)
        }
        .fullScreenCover(isPresented: $viewModel.uiState.showFeedbackModal) {
            makeFeedbackHistory()
                .environment(modalRouter)
        }
        .onAppear {
            viewModel.onAppear()

        }
        .task(id: wordLoadRequest) {
            await wordListViewModel.loadWords()
        }
        .onDisappear {
            wordListViewModel.cancelLoading()
            viewModel.onDisappear()
        }
        .onChange(of: audioService.isPlaybackActive) { _, serviceIsActive in
            viewModel.handleAudioServiceStateChange(
                isPlaybackActive: serviceIsActive,
                isPaused: audioService.isPaused
            )
        }
        .onChange(of: viewModel.uiState.showFeedbackModal) { _, isShowing in
            if isShowing {
                viewModel.stopPlayback()
            }
        }
        .animation(.easeInOut, value: viewModel.uiState.showWordList)
        .animation(.easeOut(duration: 0.2), value: viewModel.uiState.toasterMessage)
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
                        ChunkModeView(viewModel: viewModel, audioService: audioService)
                    } else {
                        SentenceModeView(viewModel: viewModel, audioService: audioService)
                    }
                }
                .padding(.horizontal, 80)
                .padding(.top, 36)
                .padding(.bottom, 48)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onChange(of: audioService.currentMultiSentenceIndex) { _, newIndex in
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
