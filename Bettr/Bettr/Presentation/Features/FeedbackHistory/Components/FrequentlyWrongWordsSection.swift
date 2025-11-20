//
//  FrequentlyWrongWordsSection.swift
//  Bettr
//
//  Created by 길정수 on 11/20/25.
//


import SwiftUI
import Charts

struct FrequentlyWrongWordsSection: View {
    let frequentlyWrongWords: [WrongWordCount]
    
    var displayWords: [String] {
        let maxCount = 5
        
        // 데이터에서 단어 문자열만 추출
        let actualWords = frequentlyWrongWords.map { $0.word }
        
        // 부족한 만큼 "-" 문자열로 채움
        let placeholdersNeeded = max(0, maxCount - actualWords.count)
        let placeholders = Array(repeating: "-", count: placeholdersNeeded)
        
        // 실제 단어와 플레이스홀더를 합쳐서 총 5개의 배열 생성
        return actualWords + placeholders
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("자주 틀린 단어")
                .font(.subbodyBold24)
                .foregroundStyle(.normalBlack900)
                .padding(8)
            
            VStack(spacing: 16) {
                ForEach(displayWords.enumerated(), id: \.offset) { (index, word) in
                    WrongWordRow(ranking: index + 1, word: word)
                }
            }
            .padding(.leading, 24)
        }
    }
}