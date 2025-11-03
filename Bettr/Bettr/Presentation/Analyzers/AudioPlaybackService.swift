//
//  AudioPlaybackService.swift
//  Bettr
//
//  Created by 길정수 on 11/3/25.
//

import AVFoundation

@Observable
final class AudioPlaybackService: NSObject, AVSpeechSynthesizerDelegate {
    
    /// true인 경우: 전체 재생, 단일 재생, 일시정지 상태입니다,
    /// false인 경우: 재생 완료, 정지, 테스크 없음 상태입니다.
    var isPlaying: Bool = false
    
    /// true인 경우: isPlaying이 true이지만 pause() 명령으로 인해 잠시 멈춰있는 경우입니다.
    var isPaused: Bool {
        synthesizer.isPaused
    }
    
    private let synthesizer = AVSpeechSynthesizer()
    private var utteranceQueue: [AVSpeechUtterance] = []
    
    override init() {
        super.init()
        synthesizer.delegate = self
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error.localizedDescription)")
        }
    }
    
    // --- Public API ---
    
    /// 특정 텍스트 하나만 재생합니다. (청크 또는 문장 탭 시 사용)
    func play(text: String, language: String = "en-US") {
        
        stop() // 기존 큐 중지
        
        // 읽어주기를 원하는 텍스트를 큐에 넣고 읽기 요청
        let utterance = createUtterance(text: text, language: language)
        synthesizer.speak(utterance)
        
        // 재생 중(테스크 처리중)으로 설정
        isPlaying = true
    }
    
    /// 스크립트 전체 문장을 순서대로 재생합니다. (전체 재생 버튼용)
    func playAll(sentences: [SentenceData], language: String = "en-US") {
        stop() // 기존 큐 중지
        
        // SentenceData 배열을 AVSpeechUtterance 배열로 변환
        self.utteranceQueue = sentences
            .sorted { $0.orderIndex < $1.orderIndex } // 순서 보장
            .map { createUtterance(text: $0.englishText, language: language) }
        
        // 큐의 첫 번째 항목부터 재생 시작
        playNextInQueue()
    }
    
    /// 재생을 일시 중지합니다.
    func pause() {
        if synthesizer.isSpeaking {
            synthesizer.pauseSpeaking(at: .immediate)
        }
    }
    
    /// 일시 중지된 지점부터 다시 재생합니다.
    func resume() {
        if synthesizer.isPaused {
            synthesizer.continueSpeaking()
        }
    }
    
    /// 재생을 완전히 중지하고 큐를 비웁니다.
    func stop() {
        if synthesizer.isSpeaking || synthesizer.isPaused {
            synthesizer.stopSpeaking(at: .immediate)
            utteranceQueue.removeAll()
            isPlaying = false
        }
    }
    
    // --- AVSpeechSynthesizerDelegate Callbacks ---
    
    /// 한 문장의 재생이 완료되었을 때 호출됩니다.
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        if !utteranceQueue.isEmpty {
            playNextInQueue()
        } else {
            isPlaying = false
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        isPlaying = true
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        if utteranceQueue.isEmpty {
            isPlaying = false
        }
    }
    
    // --- Private Helpers ---
    
    private func createUtterance(text: String, language: String) -> AVSpeechUtterance {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate // 기본 속도
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        return utterance
    }
    
    // utteranceQueue를 순서대로 처리
    private func playNextInQueue() {
        guard !utteranceQueue.isEmpty else {
            // 큐가 비었으면 재생 완료
            isPlaying = false
            return
        }
        
        let utterance = utteranceQueue.removeFirst()
        synthesizer.speak(utterance)
        isPlaying = true
    }
}
