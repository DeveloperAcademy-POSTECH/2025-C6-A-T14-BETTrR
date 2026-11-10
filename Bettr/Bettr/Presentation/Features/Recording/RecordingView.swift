//
//  RecordingView.swift
//  Bettr
//
//  Created by 길정수 on 10/30/25.
//

import SwiftUI
import Lottie

struct RecordingView: View {
    @Environment(NavigationRouter.self) private var modalRouter
    
    @State private var viewModel: RecordingViewModel
    @State private var showUnsavedDataAlert = false
    
    private let scriptTitle: String
    
    init(
        scriptTitle: String,
        viewModel: RecordingViewModel
    ) {
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
                    RecordingButtonGroup(
                        viewModel: viewModel,
                        onSaveAction: { viewModel.saveFeedback() }
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
        .onChange(of: viewModel.completion) { _, _ in showFeedbackResult() }
        .onDisappear { viewModel.leave() }
        .alert("인식된 영문 텍스트가 없습니다.", isPresented: failureBinding(.emptyTranscript)) {
            Button("확인") { }
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
        .alert("오류", isPresented: errorBinding) {
            Button("확인") { }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .alert("마이크 및 음성 인식 권한 필요", isPresented: failureBinding(.permissionDenied)) {
            Button("설정으로 이동") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("취소", role: .cancel) { }
        } message: {
            Text("피드백을 제공하기 위해 마이크와 음성 인식 권한이 필요합니다. 설정에서 권한을 허용해주세요.")
        }
    }
    
    private func failureBinding(_ failure: RecordingFailure) -> Binding<Bool> {
        Binding(
            get: { viewModel.failure == failure },
            set: { if !$0 { viewModel.dismissFailure() } }
        )
    }
    
    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.dismissFailure() } }
        )
    }
    
    private func showFeedbackResult() {
        guard let result = viewModel.consumeCompletion() else { return }
        modalRouter.push(ModalRoute.feedbackResult(summaryId: result.summaryID, fromRecording: true))
    }
}
