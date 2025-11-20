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
    
    @State private var speechRecognizer: SpeechRecognizer
    @State private var showEmptyTranscriptAlert = false
    @State private var showUnsavedDataAlert = false
    
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
        _speechRecognizer = State(wrappedValue: SpeechRecognizer(sentences: sentences))
    }
    // MARK: - 로직 통합: 분석 -> 저장 -> 이동
    
    private func analyzeAndSave() {
        guard let diffs = speechRecognizer.analyzedDiffs,
              let practiceDuration = speechRecognizer.analyzedPracticeDuration else {
            return // 분석이 완료되지 않음
        }
        
        if diffs.isEmpty {
            showEmptyTranscriptAlert = true
            return
        }
        
        Task {
            let processor = FeedbackResultProcessor()
            
            // ✅ 1. Processor를 사용하여 DB 저장에 필요한 모든 통계를 한 번에 계산
            let summaryStats = processor.createFeedbackParamsAndSummaryStats(
                fromLiveAnalysis: diffs,
                sentences: speechRecognizer.sentences,
                practiceDuration: practiceDuration
            )
            
            do {
                // 2. DB 저장 및 Summary 객체 반환
                let summary = try await container.scriptManagementService.createFeedbackSummary(
                    scriptId: self.scriptId,
                    accuracy: summaryStats.accuracy,
                    missingWordCount: summaryStats.missingCount,
                    addedWordCount: summaryStats.extraCount,
                    replacedWordCount: summaryStats.replacedCount,
                    practiceDuration: summaryStats.practiceDuration,
                    feedbackDetailsData: summaryStats.dbDetails.map {
                        ($0.wordDiff, $0.originalText, $0.sentenceIndex, $0.wordIndex)
                    }
                )
                
                guard let summaryId = summary.id else { throw AppError.unknown("저장된 Summary ID를 찾을 수 없습니다.") }
                
                // 4. 결과 화면으로 라우팅 (Summary ID 전달)
                modalRouter.push(ModalRoute.feedbackResult(summaryId: summaryId, fromRecording: true)
                )
                
            } catch {
                print("❌ 피드백 저장/라우팅 실패: \(error)")
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .center) {
            
            Spacer(minLength: 0)
            
            // 타이머
            Text(speechRecognizer.elapsedTime.toMMSSms())
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
            
            Spacer(minLength: 0)
        }
        .safeAreaPadding(.horizontal, 180)
        .safeAreaPadding(.top, 24)
        .safeAreaPadding(.bottom, 48)
        .onChange(of: speechRecognizer.analyzedDiffs) { _, newDiffs in
            if newDiffs != nil && speechRecognizer.analyzedPracticeDuration != nil {
                analyzeAndSave()
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
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    // 녹음 데이터가 있으면 Alert
                    if speechRecognizer.hasRecorded {
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
