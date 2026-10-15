//
//  PlaybackTargetID.swift
//  Bettr
//
//  Created by 길정수 on 11/24/25.
//

import Foundation

enum PlaybackTargetID: Hashable {
    case sentence(Int)              // 문장 번호
    case chunk(ChunkIdentifier)     // 청크 ID
}
