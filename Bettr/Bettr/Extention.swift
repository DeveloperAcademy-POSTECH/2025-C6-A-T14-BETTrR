//
//  Extention.swift
//  Bettr
//
//  Created by 서세린 on 10/30/25.
//

import Foundation

// ScriptInput에서 안전한 인덱스 접근용 확장
extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
