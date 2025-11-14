//
//  MemorizationInteractionState.swift
//  Bettr
//
//  Created by 길정수 on 11/14/25.
//

import Foundation
import SwiftUI

/// '가리기' 기능과 같이 콘텐츠 상호작용과 관련된 상태
@Observable
class MemorizationInteractionState {
    var hiddenEngChunks: Set<ChunkIdentifier> = []
    var hiddenEngSentences: Set<Int> = []
    
    // 이 객체와 관련된 로직을 메서드로 제공
    func toggleHiddenState(in set: inout Set<ChunkIdentifier>, for item: ChunkIdentifier) {
        if set.contains(item) {
            set.remove(item)
        } else {
            set.insert(item)
        }
    }
    
    func toggleHiddenState(in set: inout Set<Int>, for item: Int) {
        if set.contains(item) {
            set.remove(item)
        } else {
            set.insert(item)
        }
    }
    
    func clearAllHiddenStates() {
        hiddenEngChunks.removeAll()
        hiddenEngSentences.removeAll()
    }
}
