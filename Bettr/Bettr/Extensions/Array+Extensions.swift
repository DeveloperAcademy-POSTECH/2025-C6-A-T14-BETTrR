//
//  Array+Extensions.swift
//  Bettr
//
//  Created by 길정수 on 11/21/25.
//

import Foundation

extension Array {
    /// 배열을 지정된 크기의 부분 배열로 분할
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [] }
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }

    /// 배열의 끝(가장 최근 데이터)부터 지정된 크기의 청크로 분할하여 청크 배열을 반환
    /// 각 청크 내의 요소 순서는 원래 배열의 순서를 유지
    func chunkedFromEnd(into size: Int) -> [[Element]] {
        guard !self.isEmpty, size > 0 else { return [] }
        
        // 1. 배열을 뒤집어 (가장 최근 요소부터 시작) 일반 chunked로 분할
        let reversedChunks = self.reversed().chunked(into: size)
        
        // 2. 각 청크를 다시 뒤집어 원래 순서로 복구한 후 반환
        return reversedChunks.map { Array($0.reversed()) }
    }
}
