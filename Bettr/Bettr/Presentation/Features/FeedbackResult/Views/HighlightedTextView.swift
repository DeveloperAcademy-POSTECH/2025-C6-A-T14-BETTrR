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
    /// SwiftUI의 AttributedString을 직접 사용하여 폰트 스타일이 뷰의 .font() 수정자와 올바르게 병합되도록 합니다.
    private func buildAttributedString(from diffs: [WordDiff]) -> AttributedString {
        let result = NSMutableAttributedString()
        
        let regularFont = UIFont.systemFont(ofSize: 20)
        let boldFontDescriptor = regularFont.fontDescriptor.withSymbolicTraits(.traitBold)
        let boldFont = UIFont(descriptor: boldFontDescriptor!, size: regularFont.pointSize)
        
        for (index, diff) in diffs.enumerated() {
            
            // 1. diff 케이스에 따라 속성(attributes)과 텍스트를 정합니다.
            switch diff {
            case .matched(let word):
                let attributes: [NSAttributedString.Key: Any] = [
                    .foregroundColor: UIColor.normalBlack900,
                    .font: regularFont
                ]
                result.append(NSAttributedString(string: word, attributes: attributes))
                
            case .missing(let expected):
                let attributes: [NSAttributedString.Key: Any] = [
                    .foregroundColor: UIColor.alertRed01,
                    .underlineStyle: NSUnderlineStyle.single.rawValue,
                    .underlineColor: UIColor.alertRed01,
                    .font: boldFont
                ]
                result.append(NSAttributedString(string: expected, attributes: attributes))
                
            case .extra(let actual):
                let attributes: [NSAttributedString.Key: Any] = [
                    .foregroundColor: UIColor.alertRed01,
                    .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                    .strikethroughColor: UIColor.alertRed01,
                    .font: regularFont
                ]
                result.append(NSAttributedString(string: actual, attributes: attributes))
                
            case .replaced(let expected, let actual):
                // 'replaced'는 두 개의 NSAttributedString을 순서대로 추가합니다.
                let actualAttributes: [NSAttributedString.Key: Any] = [
                    .foregroundColor: UIColor.alertRed01,
                    .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                    .strikethroughColor: UIColor.alertRed01,
                    .font: regularFont
                ]
                result.append(NSAttributedString(string: actual, attributes: actualAttributes))
                
                let expectedAttributes: [NSAttributedString.Key: Any] = [
                    .foregroundColor: UIColor.alertRed01,
                    .font: boldFont
                ]
                result.append(NSAttributedString(string: " \(expected)", attributes: expectedAttributes))
            }
            
            // 2. 마지막 단어가 아니라면 띄어쓰기를 추가합니다.
            // (단, .replaced 케이스는 띄어쓰기를 이미 포함했으므로 제외)
            if index < diffs.count - 1 {
                if case .replaced = diff {
                    // .replaced는 띄어쓰기를 처리했으므로
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
