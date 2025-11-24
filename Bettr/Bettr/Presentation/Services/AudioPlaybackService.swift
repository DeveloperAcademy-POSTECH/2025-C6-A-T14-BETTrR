//
//  AudioPlaybackService.swift
//  Bettr
//
//  Created by 길정수 on 11/3/25.
//

import AVFoundation

@MainActor
enum PlaybackMode {
    case stopped
    case single // 부분 재생 (문장/청크 하나 재생)
    case multi  // 전체 재생
}

@Observable
final class AudioPlaybackService: NSObject, AVSpeechSynthesizerDelegate {
    var isPlaybackActive: Bool = false
    
    var isPaused: Bool {
        synthesizer.isPaused
    }
    
    var currentPlaybackMode: PlaybackMode = .stopped
    
    /// 전체 재생 모드에서만 사용되는 현재 문장 인덱스
    var currentMultiSentenceIndex: Int? = nil
    
    /// 단일 재생/전체 재생의 현재 텍스트 ID
    var currentPlayingSentenceIndex: Int? = nil
    
    /// 현재 재생 중인 텍스트
    var currentSpokenTextID: String? = nil
    
    /// 현재 재생 중인 대상의 고유 ID
    var currentPlaybackID: AnyHashable? = nil
    
    /// 현재까지 재생된 텍스트 범위 (NSRange)
    var currentSpokenRange: NSRange? = nil
    
    private let synthesizer = AVSpeechSynthesizer()
    private var utteranceQueue: [(index: Int, utterance: AVSpeechUtterance)] = []
    
    /// 발화 속도 (기본 0.5보다 느리게 설정)
    private let speechRate: Float = 0.45
    
    /// 문장과 문장 사이 딜레이
    private let interSentenceDelay: TimeInterval = 0.5
    
    override init() {
        super.init()
        synthesizer.delegate = self
    }
    
    // --- Private Session Helpers ---
    
    /// 재생 세션을 활성화하고 카테고리를 .playback으로 설정합니다.
    private func activatePlaybackSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to activate playback session: \(error.localizedDescription)")
        }
    }
    
    /// 오디오 세션을 비활성화합니다. (다른 앱이 오디오를 사용할 수 있도록)
    private func deactivateSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to deactivate audio session: \(error.localizedDescription)")
        }
    }
    
    // --- Public API ---
    
    /// 특정 텍스트 하나만 재생합니다. (청크 또는 문장 탭 시 사용)
    func play(text: String, id: AnyHashable, language: String = "en-US") {
        self.currentPlaybackMode = .single
        self.currentMultiSentenceIndex = nil
        self.currentSpokenTextID = text
        self.currentPlaybackID = id
        self.currentSpokenRange = nil
        
        synthesizer.stopSpeaking(at: .immediate)
        
        activatePlaybackSession()
        
        let utterance = createUtterance(text: text, language: language)
        synthesizer.speak(utterance)
    }
    
    /// 스크립트 전체 문장을 순서대로 재생합니다. (전체 재생 버튼용)
    func playAll(sentences: [SentenceData], language: String = "en-US") {
        if synthesizer.isSpeaking || synthesizer.isPaused {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        self.utteranceQueue.removeAll()
        self.currentPlaybackMode = .multi
        self.currentSpokenTextID = nil
        self.currentPlaybackID = nil
        self.currentSpokenRange = nil
        
        activatePlaybackSession()
        
        let sortedSentences = sentences
            .sorted { $0.orderIndex < $1.orderIndex }
        
        self.utteranceQueue = sortedSentences
            .map { (index: $0.orderIndex, utterance: createUtterance(text: $0.englishText, language: language)) }
        
        print("--- PLAY ALL START ---")
        print("Total Sentences in Queue: \(self.utteranceQueue.count)")
        
        playNextInQueue()
    }
    
    /// 재생을 일시 중지합니다.
    func pause() {
        if synthesizer.isSpeaking {
            synthesizer.pauseSpeaking(at: .immediate)
            deactivateSession()
        }
    }
    
    /// 일시 중지된 지점부터 다시 재생합니다.
    func resume() {
        if synthesizer.isPaused {
            activatePlaybackSession()
            synthesizer.continueSpeaking()
        }
    }
    
    /// 재생을 완전히 중지하고 큐를 비웁니다.
    func stop() {
        if synthesizer.isSpeaking || synthesizer.isPaused {
            synthesizer.stopSpeaking(at: .immediate)
            utteranceQueue.removeAll()
            self.isPlaybackActive = false
            self.currentPlaybackID = nil
        }
    }
    
    // --- AVSpeechSynthesizerDelegate Callbacks ---
    
    /// 발화가 시작될 때
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        // 콜백이 서브 스레드에서 올 수 있으므로 메인 스레드로 전달
        DispatchQueue.main.async {
            self.isPlaybackActive = true
            self.currentSpokenTextID = utterance.speechString
            self.currentSpokenRange = NSRange(location: 0, length: 0)
        }
    }
    
    /// 특정 범위의 발화를 "시작할 예정"일 때 (핵심)
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString range: NSRange, utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            // "지금까지 말한 범위" = 시작점(0)부터 방금 말한 범위의 끝까지
            let newLength = range.location + range.length
            self.currentSpokenRange = NSRange(location: 0, length: newLength)
        }
    }
    
    /// 한 문장의 재생이 완료되었을 때 호출됩니다.
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            
            print("--- DID FINISH ---")
            print("Finished Utterance: \(utterance.speechString.prefix(20))...")
            print("Queue Count Before Check: \(self.utteranceQueue.count)")
            
            if !self.utteranceQueue.isEmpty {
                print("Action: Scheduling next utterance.")
                DispatchQueue.main.asyncAfter(deadline: .now() + self.interSentenceDelay) { [weak self] in
                    self?.playNextInQueue()
                }
            } else {
                print("Action: Queue is EMPTY. Stopping playback.")
                if self.currentSpokenTextID == utterance.speechString {
                    self.isPlaybackActive = false
                    self.currentMultiSentenceIndex = nil
                    self.deactivateSession()
                    self.currentPlaybackMode = .stopped
                    self.currentSpokenTextID = nil
                    self.currentSpokenRange = nil
                    self.currentPlaybackID = nil
                }
            }
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        isPlaybackActive = true
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            if self.currentSpokenTextID == utterance.speechString {
                self.currentSpokenTextID = nil
                self.currentSpokenRange = nil
                self.currentPlaybackMode = .stopped
                self.currentMultiSentenceIndex = nil
                self.deactivateSession()
                self.currentPlaybackID = nil
            }
        }
    }
    
    // --- Private Helpers ---
    
    private func createUtterance(text: String, language: String) -> AVSpeechUtterance {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = self.speechRate
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        return utterance
    }
    
    // utteranceQueue를 순서대로 처리
    private func playNextInQueue() {
        print("--- PLAY NEXT IN QUEUE ---")
        print("Queue Count at Start: \(utteranceQueue.count)")
        
        guard !utteranceQueue.isEmpty else {
            print("Error: playNextInQueue called with empty queue. Stopping.")
            self.currentPlaybackMode = .stopped
            self.isPlaybackActive = false
            self.currentMultiSentenceIndex = nil
            deactivateSession()
            return
        }
        
        let (index, utterance) = utteranceQueue.removeFirst()
        print("Action: Starting index \(index) - Text: \(utterance.speechString.prefix(20))...")
        print("Queue Count After Removal: \(utteranceQueue.count)") // 큐에서 제거된 후 크기 확인
        
        self.currentMultiSentenceIndex = index
        self.currentSpokenTextID = utterance.speechString
        
        synthesizer.speak(utterance)
        self.isPlaybackActive = true
    }
}
