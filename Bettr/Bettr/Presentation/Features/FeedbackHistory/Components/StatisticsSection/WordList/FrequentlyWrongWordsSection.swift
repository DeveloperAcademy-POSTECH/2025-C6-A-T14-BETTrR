//
//  FrequentlyWrongWordsSection.swift
//  Bettr
//
//  Created by 길정수 on 11/23/25.
//

import SwiftUI

struct FrequentlyWrongWordsSection: View {
    let wrongWords: [WrongWordCount]
    let maxDisplayCount: Int
    
    var body: some View {
        TitledSection.standard(title: "자주 틀린 단어") {
            FrequentlyWrongWordList(
                frequentlyWrongWords: wrongWords,
                maxDisplayCount: maxDisplayCount
            )
        }
    }
}
