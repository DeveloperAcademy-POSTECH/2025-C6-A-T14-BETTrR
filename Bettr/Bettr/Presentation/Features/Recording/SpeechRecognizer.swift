//
//  SpeechRecognizer.swift
//  Bettr
//
//  Created by 길정수 on 10/30/25.
//

import SwiftUI
import Speech
import AVFoundation
import Combine
import Observation

// MARK: - 음성 인식기
@MainActor
@Observable
class SpeechRecognizer {
    var transcript = ""
    var isRecording = false
    var hasRecorded: Bool = false
    var recordingDidFinishEmpty: Bool = false
    var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    var microphoneAuthorizationStatus: AVAudioApplication.recordPermission = .undetermined
    var analyzedDiffs: [WordDiff]? = nil
    var analyzedPracticeDuration: TimeInterval? = nil
    
    
    // 실시간 경과 시간
    var elapsedTime: TimeInterval = 0.0
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    // 타이머 및 시작 시간 변수
    private var timer: Timer?
    private var recordingStartTime: Date?
    
    /// 전체 스크립트 문장들
    var sentences: [String] = []
    /// 합쳐진 전체 스크립트
    var fullScript: String {
        sentences.joined(separator: " ")
    }
    
    private var lastTranscription: SFTranscription?
    private var lastRecordedDuration: TimeInterval = 0.0
    
    init(sentences: [String]) {
        self.sentences = sentences
        self.microphoneAuthorizationStatus = AVAudioApplication.shared.recordPermission
        self.checkAuthorization()
    }
    
    // MARK: - 권한 확인
    func checkAuthorization() {
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
    
    // MARK: - 녹음 상태 변경 (녹음 중인 경우: 녹음을 끝냄, 녹음 중이 아닌 경우: 녹음을 시작)
    func toggleRecording() {
        if audioEngine.isRunning {
            stopRecording()
            return
        }
        
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
            
            if let result = result {
                Task { @MainActor in
                    self.transcript = result.bestTranscription.formattedString
                }
            }
            
            if error != nil || (result?.isFinal ?? false) {
                // 녹음 종료 시 타이머 중지
                self.timer?.invalidate()
                self.timer = nil
                
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                // 오디오 세션 비활성화
                let audioSession = AVAudioSession.sharedInstance()
                try? audioSession.setActive(false, options: .notifyOthersOnDeactivation)
                
                let totalTime = self.recordingStartTime.map { Date().timeIntervalSince($0) } ?? 0.0
                let finalTranscript = result?.bestTranscription.formattedString ?? ""
                
                Task { @MainActor in
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
            self.timer?.invalidate() // 혹시 모를 타이머 정리
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
    
    // MARK: - 녹음 종료
    func stopRecording() {
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
    
    // MARK: - 녹음 취소 (분석 실행 X)
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
    
    // MARK: - 분석 초기화
    func clearTranscript() {
        transcript = ""
        self.hasRecorded = false
        elapsedTime = 0.0
        
        lastTranscription = nil
        lastRecordedDuration = 0.0
        recordingDidFinishEmpty = false
    }
    
    // MARK: - 녹음 분석
    @MainActor
    func triggerAnalysis() {
        guard let transcription = lastTranscription else {
            print("분석할 트랜스크립션이 없습니다.")
            return
        }
        
        let analyzer = SpeechAnalyzer()
        let diffs = analyzer.analyze(reference: fullScript, transcription: transcription)
        
        self.analyzedDiffs = diffs
        self.analyzedPracticeDuration = self.lastRecordedDuration
    }
}

// MARK: - 시간 포매터
extension TimeInterval {
    /// MM:SS:ms (분:초:밀리초) 형식의 문자열로 변환합니다.
    func toMMSSms() -> String {
        let totalSeconds = self
        let minutes = Int(totalSeconds / 60)
        let seconds = Int(totalSeconds.truncatingRemainder(dividingBy: 60))
        let milliseconds = Int((totalSeconds.truncatingRemainder(dividingBy: 1)) * 100) // 3자리
        
        return String(format: "%02d:%02d.%02d", minutes, seconds, milliseconds)
    }
}
