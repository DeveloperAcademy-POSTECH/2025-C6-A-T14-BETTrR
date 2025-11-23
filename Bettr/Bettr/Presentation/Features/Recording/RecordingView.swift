//
//  RecordingView.swift
//  Bettr
//
//  Created by 길정수 on 10/30/25.
//

import SwiftUI
import Lottie

struct RecordingView: View {
    @Environment(DatabaseContainer.self) private var container
    @Environment(NavigationRouter.self) private var modalRouter
    
    @State private var viewModel: RecordingViewModel
    @State private var showUnsavedDataAlert = false
    
    private let scriptId: Int64
    private let scriptTitle: String
    
    init(
        scriptId: Int64,
        scriptTitle: String,
        viewModel: RecordingViewModel
    ) {
        self.scriptId = scriptId
        self.scriptTitle = scriptTitle
        _viewModel = State(initialValue: viewModel)
    }
    
    var body: some View {
        ZStack {
            VStack(alignment: .center) {
                Spacer()
                
                VStack(spacing: 48) {
                    // 타이머
                    Text(viewModel.elapsedTime.toMMSSms())
                        .font(.labelMedium64)
                        .foregroundStyle(.normalBlack900)
                        .padding(.top, 48)
                    
                    // 로띠
                    LottieView(animation: .named("recordLottie"))
                        .playbackMode(viewModel.isRecording ?
                            .playing(.fromProgress(0, toProgress: 1, loopMode: .loop)) :
                                .paused(at: .progress(0))
                        )
                        .animationSpeed(2.0)
                        .frame(maxWidth: .infinity, maxHeight: 500)
                        .padding(.horizontal, 48)
                    
                    // 버튼
                    RecordingControlBar(
                        viewModel: viewModel,
                        onSaveAction: {
                            Task {
                                if let summaryId = await viewModel.processAndSaveFeedback(scriptId: scriptId) {
                                    modalRouter.push(ModalRoute.feedbackResult(summaryId: summaryId, fromRecording: true))
                                }
                            }
                        }
                    )
                }
                
                Spacer()
            }
            
            // 로딩
            if viewModel.isLoading {
                Color.normalBlack900.opacity(0.1)
                    .ignoresSafeArea()
                
                ProgressView()
            }
        }
        .safeAreaPadding(.horizontal, 84)
        .safeAreaPadding(.top, 24)
        .safeAreaPadding(.bottom, 48)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    if viewModel.hasRecorded {
                        showUnsavedDataAlert = true
                    } else {
                        modalRouter.pop()
                    }
                } label: {
                    Image(systemName: "chevron.backward")
                }
            }
        }
        .alert("인식된 영문 텍스트가 없습니다.", isPresented: $viewModel.showEmptyTranscriptAlert) {
            Button("확인") { viewModel.cancelRecording() }
        } message: {
            Text("피드백 생성을 위해 인식된 영문 텍스트가 있어야 합니다. 다시 녹음 해주세요.")
        }
        .alert("분석하지 않고 나가시겠어요?", isPresented: $showUnsavedDataAlert) {
            Button("취소", role: .cancel) { }
            Button("나가기", role: .destructive) {
                modalRouter.pop()
            }
        } message: {
            Text("현재 녹음에서 인식된 영문 텍스트가 있습니다. 저장되지 않은 데이터는 사라집니다.")
        }
        .alert(item: $viewModel.appError) { error in
            Alert(
                title: Text("오류"),
                message: Text(error.userFriendlyMessage),
                dismissButton: .default(Text("확인"))
            )
        }
    }
}
