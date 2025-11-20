//
//  RecordingView.swift
//  Bettr
//
//  Created by 길정수 on 10/30/25.
//

import SwiftUI
import Speech

struct RecordingView: View {
    @Environment(DatabaseContainer.self) private var container
    @Environment(NavigationRouter.self) private var modalRouter
    
    @State private var viewModel: RecordingViewModel
    @State private var showEmptyTranscriptAlert = false
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
    
    // MARK: - 로직 통합: 분석 -> 저장 -> 이동
    
    private func processAnalysisAndSave() {
        Task {
            do {
                let summaryId = try await viewModel.saveFeedback(scriptId: scriptId)
                
                modalRouter.push(ModalRoute.feedbackResult(summaryId: summaryId, fromRecording: true))
                
            } catch let error as RecordingViewModel.RecordingError {
                if case .emptyTranscript = error {
                    showEmptyTranscriptAlert = true
                } else {
                    print("❌ 피드백 저장/라우팅 실패: \(error)")
                }
            } catch {
                print("❌ 피드백 저장/라우팅 실패: \(error)")
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .center) {
            
            Spacer(minLength: 0)
            
            // 타이머
            Text(viewModel.elapsedTime.toMMSSms())
                .font(.labelMedium64)
                .foregroundStyle(.normalBlack900)
            
            Spacer(minLength: 60)
            
            Image(.waveForm)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 48)
            
            Spacer(minLength: 60)
            
            HStack(spacing: 30) {
                let isRecording = viewModel.isRecording
                let hasRecorded = viewModel.hasRecorded
                
                let isReadyToRecord = !isRecording && !hasRecorded
                let didFinishRecording = hasRecorded && !isRecording
                
                Button(action: { viewModel.cancelRecording() }) {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(SecondaryRecordingButtonStyle())
                .disabled(!didFinishRecording)
                
                Spacer()
                
                Button(action: { viewModel.toggleRecording() }) {
                    Image(systemName: isReadyToRecord ? "microphone" : "stop.fill")
                }
                .buttonStyle(RecordingButtonStyle(isRecording: isRecording))
                .disabled(viewModel.authorizationStatus != .authorized ||
                          viewModel.microphoneAuthorizationStatus != .granted ||
                          didFinishRecording
                )
                
                Spacer()
                
                Button(action: { processAnalysisAndSave() }) {
                    Image(systemName: "arrow.right")
                }
                .buttonStyle(RecordingButtonStyle(isRecording: false))
                .disabled(!didFinishRecording)
            }
            
            Spacer(minLength: 0)
        }
        .safeAreaPadding(.horizontal, 180)
        .safeAreaPadding(.top, 24)
        .safeAreaPadding(.bottom, 48)
        .onChange(of: viewModel.recordingDidFinishEmpty) { _, isEmpty in
            if isEmpty {
                showEmptyTranscriptAlert = true
                viewModel.recordingDidFinishEmpty = false
            }
        }
        .alert("인식된 영문 텍스트가 없습니다.", isPresented: $showEmptyTranscriptAlert) {
            Button("확인") { viewModel.cancelRecording() }
        } message: {
            Text("피드백 생성을 위해 인식된 영문 텍스트가 있어야 합니다. 다시 녹음 해주세요.")
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    // 녹음 데이터가 있으면 Alert
                    if viewModel.hasRecorded {
                        showUnsavedDataAlert = true
                    } else {
                        // 없으면 바로 뒤로
                        modalRouter.pop()
                    }
                } label: {
                    Image(systemName: "chevron.backward")
                }
            }
        }
        .alert("분석하지 않고 나가시겠어요?", isPresented: $showUnsavedDataAlert) {
            Button("취소", role: .cancel) { }
            Button("나가기", role: .destructive) {
                modalRouter.pop()
            }
        } message: {
            Text("현재 녹음에서 인식된 영문 텍스트가 있습니다. 저장되지 않은 데이터는 사라집니다.")
        }
    }
}
