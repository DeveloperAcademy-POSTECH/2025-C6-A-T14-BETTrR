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
    
    init(
        scriptId: Int64,
        sentences: [String],
    ) {
        self.scriptId = scriptId
        _speechRecognizer = StateObject(wrappedValue: SpeechRecognizer(sentences: sentences))
    }
    
    var body: some View {
        NavigationStack(path: $modalRouter.path) {
            VStack(alignment: .center, spacing: 24) {
                Text(speechRecognizer.isRecording ? "네 듣고잇어요....": "녹음ㄱㄱ?")
                    .font(.title2)
                    .bold()
                
                // 실시간 타이머
                if speechRecognizer.isRecording {
                    Text(speechRecognizer.elapsedTime.toMMSSms()) // 포매터 사용
                        .font(.headline)
                        .foregroundColor(.gray)
                        .padding(.bottom, 10)
                } else {
                    // 타이머가 없을 때 레이아웃이 깨지지 않도록 빈 공간 확보
                    Text("00:00.00")
                        .font(.headline)
                        .foregroundColor(.clear) // 투명하게
                        .padding(.bottom, 10)
                }
                
                Image(systemName: "microphone")
                    .font(.system(size: 120))
                
                // 버튼
                
                if !speechRecognizer.isRecording {
                    VStack(spacing: 20) {
                        Button(action: { speechRecognizer.startRecording() }) {
                            Label("시작", systemImage:"mic.circle.fill")
                                .padding()
                                .frame(maxWidth: 500)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        .disabled(
                            speechRecognizer.authorizationStatus != .authorized ||
                            speechRecognizer.microphoneAuthorizationStatus != .granted
                        )
                        Button(action: {}) {
                            Label("취소", systemImage: "trash")
                                .padding()
                                .frame(maxWidth: 500)
                        }
                        .hidden()
                    }
                    .padding(.horizontal)
                } else {
                    VStack(spacing: 20) {
                        Button(action: {
                            if speechRecognizer.transcript.isEmpty {
                                // 텍스트가 비어있으면:
                                // 1. 녹음을 (분석 없이) 취소합니다.
                                speechRecognizer.cancelRecording()
                                // 2. 알림창을 띄웁니다.
                                showEmptyTranscriptAlert = true
                            } else {
                                // 텍스트가 있으면:
                                // 정상적으로 분석을 시작합니다.
                                speechRecognizer.stopRecording()
                            }
                        }) {
                            Label("완료", systemImage: "stop.circle.fill")
                                .padding()
                                .frame(maxWidth: 500)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        
                        Button(action: {
                            speechRecognizer.cancelRecording()
                        }) {
                            Label("취소", systemImage: "trash")
                                .padding()
                                .frame(maxWidth: 500)
                                .background(Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .onChange(of: speechRecognizer.analyzedDiffs) { _, newDiffs in
                if let diffs = newDiffs, let practiceDuration = speechRecognizer.analyzedPracticeDuration {
                    // 1. 결과 화면으로 이동
                    modalRouter.push(ModalRoute.feedbackResult(
                        diffs: diffs,
                        practiceDuration: practiceDuration,
                        sentences: speechRecognizer.sentences
                    ))
                    
                    // 2. 이동 직후, 다음 세션을 위해 상태를 초기화합니다.
                    speechRecognizer.clearTranscript()
                    speechRecognizer.analyzedDiffs = nil // Clear after use
                    speechRecognizer.analyzedPracticeDuration = nil // Clear after use
                }
            }
            .alert("알림", isPresented: $showEmptyTranscriptAlert) {
                Button("확인") { }
            } message: {
                Text("인식된 영어 텍스트가 없습니다!")
            }
            .cancelToolbar()
            .navigationDestination(for: ModalRoute.self) { route in
                switch route {
                case .feedbackResult(let diffs, let practiceDuration, let sentences):
                    let viewModel = FeedbackViewModel(
                        scriptId: self.scriptId,
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
