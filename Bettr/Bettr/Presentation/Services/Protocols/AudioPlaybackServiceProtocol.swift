//
//  AudioPlaybackServiceProtocol.swift
//  Bettr
//
//  Created by 길정수 on 11/3/25.
//

import Foundation

protocol AudioPlaybackServiceProtocol {
    
    var isPlaying: Bool { get }
    var isPaused: Bool { get }
    
    var currentPlaybackMode: PlaybackMode { get }
    
    var currentSpokenTextID: String? { get }
    
    func play(text: String, language: String)
    
    func playAll(sentences: [SentenceData], language: String)
    
    func stop()
    func pause()
    func resume()
}

extension AudioPlaybackServiceProtocol {
    
    func play(text: String) {
        self.play(text: text, language: "en-US")
    }
    
    func playAll(sentences: [SentenceData]) {
        self.playAll(sentences: sentences, language: "en-US")
    }
}

extension AudioPlaybackService: AudioPlaybackServiceProtocol { }
