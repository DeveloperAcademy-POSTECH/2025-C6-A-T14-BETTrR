//
//  RecordingViewModel.swift
//  Bettr
//
//  Created by 길정수 on 10/30/25.
//

import SwiftUI
import Speech
import AVFoundation
import Observation

@MainActor
@Observable
class RecordingViewModel {
    
    // MARK: - State Properties
    var transcript = ""
    var isRecording = false
    var hasRecorded: Bool = false
    var recordingDidFinishEmpty: Bool = false
    var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    var microphoneAuthorizationStatus: AVAudioApplication.recordPermission = .undetermined
    var elapsedTime: TimeInterval = 0.0
    
    // MARK: - Dependencies & Private
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    private var timer: Timer?
    private var recordingStartTime: Date?
    
    // 분석/저장 관련 Dependencies
    private let analyzer = SpeechAnalyzer() // WordDiff 계산 담당
    private let processor: RecordingProcessor
    private let scriptManagementService: ScriptManagementServiceProtocol
    
    /// 전체 스크립트 문장들
    var sentences: [String] = []
    /// 합쳐진 전체 스크립트
    var fullScript: String {
        sentences.joined(separator: " ")
    }
    
    private var lastTranscription: SFTranscription?
    private var lastRecordedDuration: TimeInterval = 0.0
    
    
    // MARK: - Helper Computed Properties (뷰 로직 간소화용)
        
        /// 녹음 대기 상태 (녹음 중도 아니고, 완료된 녹음도 없음)
        var isReadyToRecord: Bool {
            !isRecording && !hasRecorded
        }
        
        /// 녹음이 완료되어 결과물이 있는 상태
        var didFinishRecording: Bool {
            hasRecorded && !isRecording
        }
        
        /// 권한이 모두 허용되어 녹음 가능한 상태인지 확인
        var canRecord: Bool {
            authorizationStatus == .authorized && microphoneAuthorizationStatus == .granted
        }
    
    // MARK: - Errors
    enum RecordingError: Error {
        case notAnalyzed
        case emptyTranscript
        case saveFailed(Error)
        
        var localizedDescription: String {
            switch self {
            case .notAnalyzed: return "분석할 녹음 데이터가 없습니다."
            case .emptyTranscript: return "인식된 텍스트가 없습니다."
            case .saveFailed(let error): return "피드백 저장 실패: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Initializer
    
    init(sentences: [String], scriptManagementService: ScriptManagementServiceProtocol) {
        self.sentences = sentences
        self.scriptManagementService = scriptManagementService
        // RecordingProcessor를 사용하여 DB 저장에 필요한 통계 처리 분리
        self.processor = RecordingProcessor(analyzer: analyzer)
        self.microphoneAuthorizationStatus = AVAudioApplication.shared.recordPermission
        self.checkAuthorization()
    }
    
    // MARK: - Public Logic
    
    // MARK: 녹음 상태 변경 (시작/중지)
    func toggleRecording() {
        if audioEngine.isRunning {
            stopRecording()
            return
        }
        
        startRecording()
    }
    
    // MARK: 녹음 취소 (분석 실행 X)
    func cancelRecording() {
        // 타이머 중지
        timer?.invalidate()
        timer = nil
        
        audioEngine.stop()
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        audioEngine.inputNode.removeTap(onBus: 0)
        
        // 오디오 세션 비활성화
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setActive(false, options: .notifyOthersOnDeactivation)
        
        // 상태 리셋
        isRecording = false
        transcript = ""
        self.hasRecorded = false
        elapsedTime = 0.0
        
        lastTranscription = nil
        lastRecordedDuration = 0.0
        recordingDidFinishEmpty = false
    }
    
    // MARK: 로직 통합: 분석 -> 저장 -> summaryId 반환 (RecordingView의 analyzeAndSave 로직 이관)
    func saveFeedback(scriptId: Int64) async throws -> Int64 {
        
        // 1. 분석 수행에 필요한 데이터 확인 및 WordDiffs 계산
        guard let transcription = lastTranscription else {
            throw RecordingError.notAnalyzed
        }
        
        let diffs = analyzer.analyze(reference: fullScript, transcription: transcription)
        let practiceDuration = self.lastRecordedDuration
        
        // 2. 빈 녹음 확인
        if diffs.isEmpty {
            throw RecordingError.emptyTranscript
        }
        
        // 3. Processor를 사용하여 DB 저장에 필요한 통계 및 상세 파라미터 생성
        let summaryStats = processor.createSummaryStats(
            fromLiveAnalysis: diffs,
            sentences: sentences,
            practiceDuration: practiceDuration
        )
        
        do {
            // 4. DB 저장 및 Summary 객체 반환
            let summary = try await scriptManagementService.createFeedbackSummary(
                scriptId: scriptId,
                accuracy: summaryStats.accuracy,
                missingWordCount: summaryStats.missingCount,
                addedWordCount: summaryStats.extraCount,
                replacedWordCount: summaryStats.replacedCount,
                practiceDuration: summaryStats.practiceDuration,
                feedbackDetailsData: summaryStats.dbDetails.map {
                    ($0.wordDiff, $0.originalText, $0.sentenceIndex, $0.wordIndex)
                }
            )
            
            guard let summaryId = summary.id else { throw RecordingError.saveFailed(AppError.unknown("저장된 Summary ID를 찾을 수 없습니다.")) }
            
            return summaryId
            
        } catch {
            throw RecordingError.saveFailed(error)
        }
    }
    
    // MARK: - Private Helpers (권한 및 녹음 상세 구현)
    
    // MARK: 권한 확인
    private func checkAuthorization() {
        // 1. 음성 인식 권한 요청
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            Task { @MainActor in
                self?.authorizationStatus = status
            }
        }
        
        // 2. 마이크 권한 명시적 요청
        AVAudioApplication.requestRecordPermission { [weak self] granted in
            let status: AVAudioApplication.recordPermission = granted ? .granted : .denied
            Task { @MainActor [weak self] in
                self?.microphoneAuthorizationStatus = status
            }
        }
    }
    
    // MARK: 녹음 시작
    private func startRecording() {
        recognitionTask?.cancel()
        recognitionTask = nil
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("오디오 세션 설정 실패: \(error)")
            return
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        recognitionRequest.shouldReportPartialResults = true
        
        let inputNode = audioEngine.inputNode
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            // 1. 실시간 트랜스크립트 업데이트
            if let result = result {
                Task { @MainActor in // Task를 사용하여 메인 스레드 업데이트
                    self.transcript = result.bestTranscription.formattedString
                }
            }
            
            // 2. 녹음 종료/오류 처리
            if error != nil || (result?.isFinal ?? false) {
                // 녹음 종료 시 처리
                self.handleRecognitionCompletion(result: result)
            }
        }
        
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        audioEngine.prepare()
        do {
            self.transcript = ""
            try audioEngine.start()
            
            // 녹음 시작 시간 기록 및 타이머 시작
            self.recordingStartTime = Date()
            self.elapsedTime = 0.0
            self.timer?.invalidate()
            self.timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { [weak self] _ in
                Task { @MainActor [weak self] in
                    guard let self = self, let startTime = self.recordingStartTime else { return }
                    self.elapsedTime = Date().timeIntervalSince(startTime)
                }
            }
            
            isRecording = true
            
        } catch {
            print("오디오 엔진 시작 실패: \(error)")
        }
    }
    
    // MARK: 녹음 중지
    private func stopRecording() {
        // 타이머 중지
        timer?.invalidate()
        timer = nil
        
        audioEngine.stop()
        recognitionRequest?.endAudio()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        // 오디오 세션 비활성화
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setActive(false, options: .notifyOthersOnDeactivation)
    }
    
    // MARK: Recognition Task 완료 시 핸들러
    private func handleRecognitionCompletion(result: SFSpeechRecognitionResult?) {
        self.timer?.invalidate()
        self.timer = nil
        
        self.audioEngine.stop()
        self.audioEngine.inputNode.removeTap(onBus: 0)
        self.recognitionRequest = nil
        self.recognitionTask = nil
        
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setActive(false, options: .notifyOthersOnDeactivation)
        
        let totalTime = self.recordingStartTime.map { Date().timeIntervalSince($0) } ?? 0.0
        let finalTranscript = result?.bestTranscription.formattedString ?? ""
        
        Task { @MainActor in // Task를 사용하여 비동기/메인 스레드 전환을 명시
            self.isRecording = false
            self.hasRecorded = true
            self.transcript = finalTranscript
            
            self.lastTranscription = result?.bestTranscription
            self.lastRecordedDuration = totalTime
            
            if finalTranscript.isEmpty {
                self.recordingDidFinishEmpty = true
            }
        }
    }
}
