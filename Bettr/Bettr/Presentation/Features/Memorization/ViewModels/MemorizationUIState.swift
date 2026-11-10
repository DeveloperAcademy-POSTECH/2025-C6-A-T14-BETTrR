//
//  MemorizationUIState.swift
//  Bettr
//
//  Created by 길정수 on 11/14/25.
//

import Foundation

/// 툴바, 모달 등 UI와 직접 연결된 상태. 재생 상태는 `AudioPlaybackServiceProtocol`이 소유하므로 두지 않는다.
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
    
    // 토스터 상태
    var toasterMessage: String? = nil
}
