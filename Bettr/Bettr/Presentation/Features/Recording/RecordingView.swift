//
//  RecordingView.swift
//  Bettr
//
//  Created by 길정수 on 10/30/25.
//

import SwiftUI
import Speech

struct RecordingView: View {
    @Environment(\.dismiss) var modalDismiss
    @Environment(DatabaseContainer.self) private var container
    
    @State private var modalRouter = NavigationRouter()
    
    @StateObject private var speechRecognizer: SpeechRecognizer
    @State private var showEmptyTranscriptAlert = false
    
    private let scriptId: Int64
    private let scriptTitle: String
    private let currentFeedbackCount: Int
    
    init(
        scriptId: Int64,
        sentences: [String],
        scriptTitle: String,
        currentFeedbackCount: Int
    ) {
        self.scriptId = scriptId
        self.scriptTitle = scriptTitle
        self.currentFeedbackCount = currentFeedbackCount
        _speechRecognizer = StateObject(wrappedValue: SpeechRecognizer(sentences: sentences))
    }
    
    var body: some View {
        NavigationStack(path: $modalRouter.path) {
            VStack(alignment: .center) {
                // 타이머
                Text(speechRecognizer.elapsedTime.toMMSSms())
                    .font(.labelMedium64)
                    .foregroundColor(.normalBlack900)

                Spacer()
                
                Image(.waveForm)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 254)
                    .padding(.horizontal, 68)
                
                Spacer()
                                
                HStack(spacing: 100) {
                    let isRecording = speechRecognizer.isRecording
                    let hasRecorded = speechRecognizer.hasRecorded
                    
                    let isReadyToRecord = !isRecording && !hasRecorded
                    let didFinishRecording = hasRecorded && !isRecording
                    
                    Button(action: { speechRecognizer.cancelRecording() }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(SecondaryRecordingButtonStyle())
                    .disabled(!didFinishRecording)
                    
                    Spacer()
                    
                    Button(action: { speechRecognizer.toggleRecording() }) {
                        Image(systemName: isReadyToRecord ? "microphone" : "stop.fill")
                    }
                    .buttonStyle(RecordingButtonStyle(isRecording: isRecording))
                    .disabled(speechRecognizer.authorizationStatus != .authorized ||
                              speechRecognizer.microphoneAuthorizationStatus != .granted ||
                              didFinishRecording
                    )

                    
                    Spacer()
                    
                    Button(action: { speechRecognizer.triggerAnalysis() }) {
                        Image(systemName: "arrow.right")
                    }
                    .buttonStyle(RecordingButtonStyle(isRecording: false))
                    .disabled(!didFinishRecording)
                }
            }
            .safeAreaPadding(.horizontal, 144)
            .safeAreaPadding(.top, 48)
            .safeAreaPadding(.bottom, 72)
            .onChange(of: speechRecognizer.analyzedDiffs) { _, newDiffs in
                if let diffs = newDiffs, let practiceDuration = speechRecognizer.analyzedPracticeDuration {
                    // 결과 화면으로 이동
                    modalRouter.push(ModalRoute.feedbackResult(
                        diffs: diffs,
                        practiceDuration: practiceDuration,
                        sentences: speechRecognizer.sentences,
                        scriptTitle: self.scriptTitle,
                        currentFeedbackCount: self.currentFeedbackCount
                    ))
                    
                    // 이동 직후, 다음 세션을 위해 상태를 초기화합니다.
                    speechRecognizer.clearTranscript()
                    speechRecognizer.analyzedDiffs = nil
                    speechRecognizer.analyzedPracticeDuration = nil
                }
            }
            .onChange(of: speechRecognizer.recordingDidFinishEmpty) { _, isEmpty in
                if isEmpty {
                    showEmptyTranscriptAlert = true
                    speechRecognizer.recordingDidFinishEmpty = false
                }
            }
            .alert("인식된 영문 텍스트가 없습니다.", isPresented: $showEmptyTranscriptAlert) {
                Button("확인") { speechRecognizer.cancelRecording() }
            } message: {
                Text("피드백 생성을 위해 인식된 영문 텍스트가 있어야 합니다. 다시 녹음 해주세요.")
            }
            .cancelToolbar()
            .navigationDestination(for: ModalRoute.self) { route in
                switch route {
                case .feedbackResult(let diffs, let practiceDuration, let sentences, let scriptTitle, let currentFeedbackCount):
                    let viewModel = FeedbackViewModel(
                        scriptId: self.scriptId,
                        scriptTitle: scriptTitle,
                        currentFeedbackCount: currentFeedbackCount,
                        diffs: diffs,
                        sentences: sentences,
                        practiceDuration: practiceDuration,
                        scriptManagementService: container.scriptManagementService
                    )
                    
                    FeedbackResultView(viewModel: viewModel)
                        .environment(\.modalDismiss, modalDismiss)
                }
            }
        }
    }
}
