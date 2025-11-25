//
//  AudioPlaybackServiceProtocol.swift
//  Bettr
//
//  Created by 길정수 on 11/3/25.
//

import Foundation

protocol AudioPlaybackServiceProtocol {
    
    var isPlaybackActive: Bool { get }
    var isPaused: Bool { get }
    
    var currentPlaybackMode: PlaybackMode { get }
    var currentSpokenTextID: String? { get }
    var currentPlaybackID: PlaybackTargetID? { get }
    
    var currentMultiSentenceIndex: Int? { get }
    var currentSpokenRange: NSRange? { get }
    
    func play(text: String, id: PlaybackTargetID, language: String)
    func playAll(sentences: [SentenceData], language: String)
    func stop()
    func pause()
    func resume()
}

extension AudioPlaybackServiceProtocol {
    func play(text: String, id: PlaybackTargetID) {
        self.play(text: text, id: id, language: "en-US")
    }
    
    func playAll(sentences: [SentenceData]) {
        self.playAll(sentences: sentences, language: "en-US")
    }
}

extension AudioPlaybackService: AudioPlaybackServiceProtocol { }
