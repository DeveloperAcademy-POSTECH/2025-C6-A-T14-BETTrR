//
//  WrongWordRow.swift
//  Bettr
//
//  Created by 길정수 on 11/20/25.
//


import SwiftUI
import Charts

struct WrongWordRow: View {
    let ranking: Int
    let word: String
    
    var body: some View {
        HStack(spacing: 16) {
            Text("\(ranking)")
                .foregroundStyle(.normalGray600)
            
            Text(word)
                .foregroundStyle(.normalBlack900)
        }
        .font(.subbodyBold24)
    }
}