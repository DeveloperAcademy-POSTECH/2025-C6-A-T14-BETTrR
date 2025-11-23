//
//  FrequentlyWrongWordsSection.swift
//  Bettr
//
//  Created by 길정수 on 11/20/25.
//


import SwiftUI
import Charts

struct FrequentlyWrongWordList: View {
    let frequentlyWrongWords: [WrongWordCount]
    let maxDisplayCount: Int
    
    var displayWords: [String] {
        // 데이터에서 단어 문자열만 추출
        let actualWords = frequentlyWrongWords
            .map { $0.word }
            .prefix(maxDisplayCount)
        
        // 부족한 만큼 "-" 문자열로 채움
        let placeholdersNeeded = max(0, maxDisplayCount - actualWords.count)
        let placeholders = Array(repeating: "-", count: placeholdersNeeded)
        
        // 실제 단어와 플레이스홀더를 합쳐서 총 5개의 배열 생성
        return actualWords + placeholders
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(displayWords.enumerated(), id: \.offset) { (index, word) in
                WrongWordRow(ranking: index + 1, word: word)
            }
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct WrongWordRow: View {
    let ranking: Int
    let word: String
    
    var body: some View {
        HStack(spacing: 16) {
            Text("\(ranking)")
                .foregroundStyle(.normalGray600)
            
            Text(word)
                .foregroundStyle(.normalBlack900)
        }
        .font(.iconBold20)
    }
}
