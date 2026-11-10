//
//  SystemSpeechSynthesizer.swift
//  Bettr
//

import AVFoundation

/// 실제 기기의 `AVSpeechSynthesizer`를 `SpeechSynthesizing`으로 감쌉니다.
@MainActor
final class SystemSpeechSynthesizer: NSObject, SpeechSynthesizing, AVSpeechSynthesizerDelegate {
    var onEvent: (@MainActor (SpeechEvent) -> Void)?

    private let synthesizer = AVSpeechSynthesizer()

    var isSpeaking: Bool { synthesizer.isSpeaking }

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(_ utterance: AVSpeechUtterance) {
        synthesizer.speak(utterance)
    }

    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
    }

    func pauseSpeaking() {
        synthesizer.pauseSpeaking(at: .immediate)
    }

    func continueSpeaking() {
        synthesizer.continueSpeaking()
    }

    // MARK: - AVSpeechSynthesizerDelegate

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        forward(utterance, .didStart)
    }

    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        willSpeakRangeOfSpeechString range: NSRange,
        utterance: AVSpeechUtterance
    ) {
        forward(utterance, .willSpeak(range: range))
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        forward(utterance, .didFinish)
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        forward(utterance, .didPause)
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        forward(utterance, .didContinue)
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        forward(utterance, .didCancel)
    }

    /// 콜백이 서브 스레드에서 올 수 있어 메인 스레드로 순서를 유지하며 전달합니다.
    private nonisolated func forward(_ utterance: AVSpeechUtterance, _ kind: SpeechEvent.Kind) {
        let event = SpeechEvent(utteranceID: ObjectIdentifier(utterance), kind: kind)
        DispatchQueue.main.async { [weak self] in
            self?.onEvent?(event)
        }
    }
}
