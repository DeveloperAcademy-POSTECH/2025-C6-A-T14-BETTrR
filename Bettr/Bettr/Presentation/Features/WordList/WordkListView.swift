//
//  WordkListView.swift
//  Bettr
//
//  Created by 길정수 on 10/29/25.
//

import SwiftUI

struct WordkListView: View {
    @Environment(DatabaseContainer.self) var container
    let scriptId: Int64
    @Binding var words: [Word]
    @Binding var isLoading: Bool
    
    var body: some View {
        VStack {
            
            if isLoading {
                WordLoadingView()
            } else if words.isEmpty {
                EmptyWordListView()
            } else {
                WordListContentView(words: $words)
            }
        }
        .padding(.top, 36)
        .padding(.bottom, 36)
        .frame(maxWidth: 360, maxHeight: .infinity, alignment: .topLeading)
        .clipShape(RoundedRectangle(cornerRadius: 35))
        .background(
            RoundedRectangle(cornerRadius: 35)
                .fill(.regularMaterial)
        )
        .glassEffect(in: .rect(cornerRadius: 35))
    }
}

// MARK: - EmptyWordListView (단어 비었을 때 뷰)
private struct EmptyWordListView: View {
    var body: some View {
        VStack(spacing: 36) {
            Image(systemName: "exclamationmark.triangle")
                .font(.bodyRegular24)
                .foregroundStyle(.normalBlack900)
            
            VStack(spacing: 12) {
                Text("단어장이 비어있어요!")
                    .font(.iconBold20)
                    .foregroundStyle(.normalBlack900)
                
                Text("추출된 단어가 없습니다.")
                    .font(.calloutRegular16)
                    .foregroundStyle(.normalBlack900)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}


#Preview {
    // MARK: - 목업 데이터를 Preview 내부에서 정의
    let localMockWords: [Word] = [
        Word(id: 1, scriptId: 1, lemma: "apple", pos: "명", meaning: "사과", orderIndex: 0),
        Word(id: 2, scriptId: 1, lemma: "run", pos: "동", meaning: "달리다", orderIndex: 1),
        Word(id: 3, scriptId: 1, lemma: "beautiful", pos: "형", meaning: "아름다운", orderIndex: 2),
        Word(id: 6, scriptId: 1, lemma: "untranslated", pos: "명", meaning: "번역되지 않은", orderIndex: 3)
    ]
    

    let mockContainer = DatabaseContainer(database: AppDatabase.shared)
    
    WordkListView(
        scriptId: 1,
        words: .constant(localMockWords), // 로컬 목업 데이터 주입
        isLoading: .constant(false)
    )
    .environment(mockContainer) // 로컬 목업 컨테이너 제공
}
