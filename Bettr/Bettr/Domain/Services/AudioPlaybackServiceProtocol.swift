//
//  AudioPlaybackServiceProtocol.swift
//  Bettr
//
//  Created by 길정수 on 11/3/25.
//

import BettrAI
import Foundation
import Observation

nonisolated enum PlaybackMode {
    case stopped
    case single
    case multi
}

/// 암기 화면 재생 상태의 유일한 소유자입니다. 같은 Observable 인스턴스를 재생 제어와 텍스트 강조에 전달합니다.
///
/// 상태의 기준은 이 프로토콜의 프로퍼티이며, ViewModel과 View는 복사하지 않고 파생해서 사용합니다.
/// - `currentPlaybackMode`: `.multi`이면 전체 재생(툴바 일시정지/정지 컨트롤), `.single`이면 문장·청크 재생.
/// - `currentPlaybackID`: 단일 재생의 대상. 텍스트가 같아도 ID가 다르면 다른 대상입니다.
/// - `currentMultiSentenceIndex`: 전체 재생 중 현재 문장. 강조와 스크롤은 이 값에서 파생됩니다.
/// - `isPaused`: 일시정지 여부. 정지·종료·새 재생 시작 시 항상 해제됩니다.
@MainActor
protocol AudioPlaybackServiceProtocol: AnyObject, Observable {
    
    var isPlaybackActive: Bool { get }
    var isPaused: Bool { get }
    
    var currentPlaybackMode: PlaybackMode { get }
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
