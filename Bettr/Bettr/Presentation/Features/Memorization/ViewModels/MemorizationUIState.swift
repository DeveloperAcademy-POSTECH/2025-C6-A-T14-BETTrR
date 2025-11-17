//
//  MemorizationUIState.swift
//  Bettr
//
//  Created by 길정수 on 11/14/25.
//

import Foundation

/// 툴바, 모달, 재생 상태 등 UI와 직접 연결된 상태
@Observable
class MemorizationUIState {
    // 툴바 상태
    var isChunkMode: Bool = false
    var funcMode: FunctionMode = .hide
    var isKoreanVisible: Bool = true
    var isTitleEditing: Bool = false
    
    // 모달/시트 상태
    var showWordList: Bool = false
    var showFeedbackModal: Bool = false
    
    // 재생 및 하이라이트 상태
    var isPlaying: Bool = false
    var isPause: Bool = false
    var tappedPlaybackText: String? = nil
    
    // 토스터 상태
    var toasterMessage: String? = nil
}
