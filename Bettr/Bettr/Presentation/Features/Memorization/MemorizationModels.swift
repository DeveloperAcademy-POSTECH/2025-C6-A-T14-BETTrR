//
//  MemorizationModels.swift
//  Bettr
//
//  Created by 길정수 on 11/3/25.
//

import Foundation

// 청크 구분자
struct ChunkIdentifier: Hashable {
    let sentenceIndex: Int
    let chunkIndex: Int
}

// 툴바 기능 모드
enum FunctionMode {
    case hide   // 가리기
    case read   // 재생
}
