//
//  SpeechSynthesizing.swift
//  Bettr
//

import AVFoundation

/// 합성기가 보내는 발화 이벤트입니다. 발화 객체는 식별자로만 전달합니다.
nonisolated struct SpeechEvent: Sendable {
    enum Kind: Sendable {
        case didStart
        case willSpeak(range: NSRange)
        case didFinish
        case didPause
        case didContinue
        case didCancel
    }

    let utteranceID: ObjectIdentifier
    let kind: Kind
}

/// `AVSpeechSynthesizer` 경계입니다. 서비스는 이 계약만 알고, 이벤트는 MainActor에서 전달됩니다.
@MainActor
protocol SpeechSynthesizing: AnyObject {
    var isSpeaking: Bool { get }
    var onEvent: (@MainActor (SpeechEvent) -> Void)? { get set }

    func speak(_ utterance: AVSpeechUtterance)
    func stopSpeaking()
    func pauseSpeaking()
    func continueSpeaking()
}
