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
            VStack(alignment: .center) {
                
                Spacer()
                
                // 타이머
                Text(speechRecognizer.elapsedTime.toMMSSms())
                    .font(.labelMedium64)
                    .foregroundColor(.normalBlack900)
                
                Spacer()
                
                // 버튼
                HStack(spacing: 300) {
                    if speechRecognizer.isRecording {
                        // MARK: - 상태 1: 녹음 중
                        
                        Button(action: { }) {
                            Image(systemName: "arrow.clockwise")
                        }
                        .buttonStyle(SecondaryRecordingButtonStyle())
                        .disabled(true)
                        
                        // 녹음 중지 버튼 (중앙)
                        Button(action: { speechRecognizer.startRecording() }) { // startRecording이 stopRecording 호출
                            Image(systemName: "stop.fill")
                        }
                        .buttonStyle(RecordingButtonStyle(isRecording: true))
                        
                        Button(action: { }) {
                            Image(systemName: "arrow.right")
                        }
                        .buttonStyle(SecondaryRecordingButtonStyle())
                        .disabled(true)
                        
                    } else if speechRecognizer.hasRecorded {
                        // MARK: - 상태 2: 검토 (녹음 완료, 스크린샷 상태)
                        
                        // 분석 취소(초기화) 버튼 (좌)
                        Button(action: { speechRecognizer.cancelRecording() }) {
                            Image(systemName: "arrow.clockwise")
                        }
                        .buttonStyle(SecondaryRecordingButtonStyle())
                        
                        // 녹음 버튼 (비활성화) (중앙)
                        Button(action: {}) {
                            Image(systemName: "stop.fill")
                        }
                        .buttonStyle(RecordingButtonStyle(isRecording: false))
                        .disabled(true)
                        
                        // 분석 완료 버튼 (우)
                        Button(action: {
                            speechRecognizer.triggerAnalysis() // [수정] 수동 분석 트리거
                        }) {
                            Image(systemName: "arrow.right")
                        }
                        .buttonStyle(RecordingButtonStyle(isRecording: false))
                        
                    } else {
                        // MARK: - 상태 3: 준비 (초기 상태)
                        
                        // 초기화 버튼 (비활성화) (좌)
                        Button(action: {}) {
                            Image(systemName: "arrow.clockwise")
                        }
                        .buttonStyle(SecondaryRecordingButtonStyle())
                        .disabled(true)
                        
                        // 녹음 시작 버튼 (중앙)
                        Button(action: { speechRecognizer.startRecording() }) {
                            Image(systemName: "microphone")
                        }
                        .buttonStyle(RecordingButtonStyle(isRecording: false))
                        .disabled(
                            speechRecognizer.authorizationStatus != .authorized ||
                            speechRecognizer.microphoneAuthorizationStatus != .granted
                        )
                        
                        // 분석 버튼 (비활성화) (우)
                        Button(action: {}) {
                            Image(systemName: "arrow.right")
                        }
                        .buttonStyle(SecondaryRecordingButtonStyle())
                        .disabled(true)
                    }
                }
                
                Spacer()
            }
            .onChange(of: speechRecognizer.analyzedDiffs) { _, newDiffs in
                if let diffs = newDiffs, let practiceDuration = speechRecognizer.analyzedPracticeDuration {
                    // 결과 화면으로 이동
                    modalRouter.push(ModalRoute.feedbackResult(
                        diffs: diffs,
                        practiceDuration: practiceDuration,
                        sentences: speechRecognizer.sentences
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
