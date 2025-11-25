//
//  RecordingViewModel.swift
//  Bettr
//
//  Created by 길정수 on 10/30/25.
//

import Foundation
import Speech
import AVFoundation

@MainActor
@Observable
class RecordingViewModel {
    
    // MARK: - Properties: Recording State
    var transcript = ""
    var isRecording = false
    var hasRecorded: Bool = false
    var elapsedTime: TimeInterval = 0.0
    
    // MARK: - Properties: UI State
    var isLoading = false
    var appError: AppError?
    var showEmptyTranscriptAlert = false
    var showPermissionAlert = false
    
    // MARK: - Properties: Permissions
    var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    var microphoneAuthorizationStatus: AVAudioApplication.recordPermission = .undetermined
    
    // MARK: - Properties: Dependencies & Core
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en"))
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    private var timer: Timer?
    private var recordingStartTime: Date?
    
    // MARK: - Properties: Analysis & Services
    private let analyzer = SpeechAnalyzer()
    private let processor: RecordingProcessor
    private let scriptManagementService: ScriptManagementServiceProtocol
    
    /// 전체 스크립트 문장 리스트
    var sentences: [String] = []
    
    /// 전체 스크립트 (분석용 결합 문자열)
    var fullScript: String {
        sentences.joined(separator: " ")
    }
    
    /// 마지막으로 완료된 음성 인식 결과 (분석용)
    private var lastTranscription: SFTranscription?
    
    /// 마지막 녹음의 총 지속 시간
    private var lastRecordedDuration: TimeInterval = 0.0
    
    // MARK: - Computed Properties (Helpers)
    
    /// 녹음 대기 상태인지 확인 (녹음 중도 아니고, 완료된 녹음도 없음)
    var isReadyToRecord: Bool {
        !isRecording && !hasRecorded
    }
    
    /// 녹음이 완료되어 결과물이 있는 상태인지 확인
    var didFinishRecording: Bool {
        hasRecorded && !isRecording
    }
    
    /// 권한이 모두 허용되어 녹음 가능한 상태인지 확인
    var canRecord: Bool {
        authorizationStatus == .authorized && microphoneAuthorizationStatus == .granted
    }
    
    // MARK: - Custom Errors
    
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
    
    /// 뷰모델을 초기화하고 권한 상태를 확인
    /// - Parameters:
    ///   - sentences: 연습할 스크립트의 문장 배열
    ///   - scriptManagementService: 데이터 저장 및 관리를 위한 서비스
    init(sentences: [String], scriptManagementService: ScriptManagementServiceProtocol) {
        self.sentences = sentences
        self.scriptManagementService = scriptManagementService
        self.processor = RecordingProcessor(analyzer: analyzer)
        self.microphoneAuthorizationStatus = AVAudioApplication.shared.recordPermission
        self.checkAuthorization()
    }
    
    // MARK: - Public Methods: User Actions
    
    /// 녹음 상태를 토글 (시작 <-> 중지)
    func toggleRecording() {
        guard canRecord else {
            showPermissionAlert = true
            return
        }
        
        if audioEngine.isRunning {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    /// 녹음을 취소하고 모든 상태를 초기화
    func cancelRecording() {
        resetRecordingState()
        
        // UI 상태 초기화
        isRecording = false
        transcript = ""
        hasRecorded = false
        elapsedTime = 0.0
        lastTranscription = nil
        lastRecordedDuration = 0.0
    }
    
    // 녹음 결과를 분석하고 DB 저장을 시도
    /// 로딩 상태(`isLoading`)와 에러 상태(`appError`)를 관리
    ///
    /// - Parameter scriptId: 연결할 스크립트 ID
    /// - Returns: 저장 성공 시 생성된 Summary ID, 실패 시 nil
    func processAndSaveFeedback(scriptId: Int64) async -> Int64? {
        isLoading = true
        defer { isLoading = false }
        
        do {
            return try await saveFeedback(scriptId: scriptId)
            
        } catch let error as RecordingError {
            if case .emptyTranscript = error {
                self.showEmptyTranscriptAlert = true
            } else if case .saveFailed(let innerError) = error {
                self.appError = .unknown("저장 중 문제가 발생했습니다.\n(\(innerError.localizedDescription))")
            } else {
                self.appError = .unknown(error.localizedDescription)
            }
            return nil
            
        } catch {
            print("❌ 피드백 저장 실패 (Unknown): \(error)")
            self.appError = .unknown(error.localizedDescription)
            return nil
        }
    }
    
    // MARK: - Private Methods: Logic
    
    /// 실제 분석 및 DB 저장을 수행하는 내부 로직
    ///
    /// - Parameter scriptId: 스크립트 ID
    /// - Returns: 저장된 Summary ID
    /// - Throws: 분석 데이터 부족, 빈 녹음, 저장 실패 등의 에러
    func saveFeedback(scriptId: Int64) async throws -> Int64 {
        guard let transcription = lastTranscription else {
            throw RecordingError.notAnalyzed
        }
        
        let diffs = analyzer.analyze(reference: fullScript, transcription: transcription)
        
        if diffs.isEmpty {
            throw RecordingError.emptyTranscript
        }
        
        let summaryStats = processor.createSummaryStats(
            fromLiveAnalysis: diffs,
            sentences: sentences,
            practiceDuration: self.lastRecordedDuration
        )
        
        do {
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
    
    // MARK: - Private Methods: Recording Control
    
    /// 음성 인식 및 마이크 접근 권한을 요청
    private func checkAuthorization() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            Task { @MainActor in
                self?.authorizationStatus = status
            }
        }
        
        AVAudioApplication.requestRecordPermission { [weak self] granted in
            Task { @MainActor [weak self] in
                self?.microphoneAuthorizationStatus = granted ? .granted : .denied
            }
        }
    }
    
    /// 오디오 엔진과 음성 인식 세션을 설정하고 녹음을 시작
    private func startRecording() {
        resetRecordingState()
        
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
            
            if let result = result {
                Task { @MainActor in
                    self.transcript = result.bestTranscription.formattedString
                    self.lastTranscription = result.bestTranscription
                }
            }
            
            if error != nil || (result?.isFinal ?? false) {
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
    
    /// 녹음을 정상적으로 중지
    private func stopRecording() {
        timer?.invalidate()
        timer = nil
        
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        
        recognitionRequest?.endAudio()
    }
    
    /// 타이머, 오디오 엔진, 인식 작업 등 녹음 관련 리소스를 정리
    private func resetRecordingState() {
        timer?.invalidate()
        timer = nil
        
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        
        recognitionTask?.cancel()
        recognitionTask = nil
    }
    
    /// 음성 인식이 종료(완료 또는 에러)되었을 때 결과를 처리
    /// - Parameter result: 음성 인식 최종 결과
    private func handleRecognitionCompletion(result: SFSpeechRecognitionResult?) {
        resetRecordingState()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        
        let finalTranscript = result?.bestTranscription.formattedString ?? ""
        let totalTime = self.recordingStartTime.map { Date().timeIntervalSince($0) } ?? 0.0
        
        Task { @MainActor in
            self.isRecording = false
            self.hasRecorded = true
            self.transcript = finalTranscript
            
            if let best = result?.bestTranscription {
                self.lastTranscription = best
            }
            self.lastRecordedDuration = totalTime
        }
    }
}
