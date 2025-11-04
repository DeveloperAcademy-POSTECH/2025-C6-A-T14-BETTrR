//
//  HighlightedTextView.swift
//  Bettr
//
//  Created by 길정수 on 11/4/25.
//

import SwiftUI
import UIKit

struct HighlightedTextView: View {
    let diffs: [WordDiff]
    
    var body: some View {
        if diffs.isEmpty {
            Text("(발화 내용 없음)")
                .foregroundStyle(.gray)
        } else {
            Text(buildAttributedString(from: diffs))
        }
    }
    
    /// diffs 배열을 기반으로 하나의 AttributedString을 생성하는 헬퍼
    private func buildAttributedString(from diffs: [WordDiff]) -> AttributedString {
        // NSAttributedString을 먼저 만들고 마지막에 AttributedString으로 변환합니다.
        // NSAttributedString이 속성을 다루기 더 유연합니다.
        let result = NSMutableAttributedString()
        
        for (index, diff) in diffs.enumerated() {
            
            // 1. diff 케이스에 따라 속성(attributes)과 텍스트를 정합니다.
            switch diff {
            case .matched(let word):
                let attributes: [NSAttributedString.Key: Any] = [
                    .foregroundColor: UIColor.label // .primary에 해당
                ]
                result.append(NSAttributedString(string: word, attributes: attributes))
                
            case .missing(let expected):
                let attributes: [NSAttributedString.Key: Any] = [
                    .foregroundColor: UIColor.systemGreen, // .green
                    .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                    .strikethroughColor: UIColor.systemGreen
                ]
                result.append(NSAttributedString(string: expected, attributes: attributes))
                
            case .extra(let actual):
                let attributes: [NSAttributedString.Key: Any] = [
                    .foregroundColor: UIColor.systemRed // .red
                ]
                result.append(NSAttributedString(string: actual, attributes: attributes))
                
            case .replaced(let expected, let actual):
                // 'replaced'는 두 개의 NSAttributedString을 순서대로 추가합니다.
                let expectedAttributes: [NSAttributedString.Key: Any] = [
                    .foregroundColor: UIColor.systemGray, // .gray
                    .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                    .strikethroughColor: UIColor.systemGray
                ]
                result.append(NSAttributedString(string: expected, attributes: expectedAttributes))
                
                let actualAttributes: [NSAttributedString.Key: Any] = [
                    .foregroundColor: UIColor.systemBlue // .blue
                ]
                // 띄어쓰기를 여기서 추가합니다.
                result.append(NSAttributedString(string: " \(actual)", attributes: actualAttributes))
            }
            
            // 2. 마지막 단어가 아니라면 띄어쓰기를 추가합니다.
            // (단, .replaced 케이스는 띄어쓰기를 이미 포함했으므로 제외)
            if index < diffs.count - 1 {
                if case .replaced = diff {
                    // .replaced는 이미 " \(actual)"로 띄어쓰기를 처리했으므로
                    // 다음 단어로 넘어가기 전에 한 칸 더 띄어줍니다.
                     result.append(NSAttributedString(string: " "))
                } else {
                    // 다른 케이스들은 단어 뒤에 띄어쓰기를 추가합니다.
                    result.append(NSAttributedString(string: " "))
                }
            }
        }
        
        // 3. 최종 NSAttributedString을 Swift의 AttributedString으로 변환하여 반환합니다.
        return AttributedString(result)
    }
}
