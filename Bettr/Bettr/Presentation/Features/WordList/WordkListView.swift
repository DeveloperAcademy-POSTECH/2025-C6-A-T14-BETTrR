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
            Spacer()
            
            if isLoading {
                VStack(spacing: 36) {
                    ProgressView()
                        .frame(width: 30, height: 30)
                        .foregroundStyle(.secondaryBlue700)
                    
                    VStack(spacing: 12) {
                        Text("단어장을 불러오는 중입니다.")
                            .font(.iconBold20)
                            .foregroundStyle(.normalBlack900)
                        
                        Text("잠시 기다려주세요.")
                            .font(.calloutRegular16)
                            .foregroundStyle(.normalBlack900)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
            } else if words.isEmpty {
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
            } else {
                ScrollView {
                    VStack {
                        ForEach(Array(words.enumerated()), id: \.element.id) { index, word in
                            VStack(alignment: .leading, spacing: 8) {
                                // Title + POS badge
                                HStack(alignment: .center, spacing: 8) {
                                    Text(word.lemma)
                                        .font(.subbodyBold24)
                                        .foregroundStyle(.normalBlack900)
                                        .padding(.trailing, 4)
                                    // POS capsule badge (한글 축약은 상위 레이어에서 처리되어 있다고 가정)
                                    Text(word.pos)
                                        .font(.footerRegular11)
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 2)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(Color.clear)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 4)
                                                        .stroke(.primaryBlue500, lineWidth: 1)
                                                )
                                        )
                                        .foregroundStyle(.primaryBlue500)
                                    Spacer(minLength: 0)
                                }
                                
                                if word.meaning.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    Text("번역 준비중…")
                                        .font(.callout)
                                        .foregroundStyle(.secondary)
                                } else {
                                    let parts = word.meaning
                                        .components(separatedBy: .newlines)
                                        .flatMap { $0.components(separatedBy: " / ") }
                                        .flatMap { $0.components(separatedBy: "; ") }
                                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                                        .filter { !$0.isEmpty }
                                    
                                    VStack(alignment: .leading, spacing: 6) {
                                        ForEach(parts, id: \.self) { item in
                                            Text(item)
                                                .font(.labelRegular14)
                                                .foregroundStyle(.primary)
                                                .multilineTextAlignment(.leading)
                                        }
                                    }
                                }
                            }
                            .padding(.top, 16)
                            .padding(.bottom, 7)
                            
                            if index != words.count - 1 {
                                Rectangle()
                                    .frame(height: 1)
                                    .foregroundStyle(.primaryBlue50)
                            }

                        }
                        .padding(.leading, 36)
                    }
                }
                .scrollIndicators(.hidden)
            }
            
            Spacer()
        }
        .padding(.top, 12)
        .frame(maxWidth: 360, maxHeight: .infinity, alignment: .topLeading)
        .clipShape(RoundedRectangle(cornerRadius: 35))
        .background(
            RoundedRectangle(cornerRadius: 35)
                .fill(.regularMaterial)
        )
        .glassEffect(in: .rect(cornerRadius: 35))
    }
}

//#Preview {
//    WordkListView(scriptId: 1, words: .constant([]), isLoading: .constant(false))
//        .environment(DatabaseContainer(database: AppDatabase.shared))
//}

#Preview {
    // MARK: - 목업 데이터를 Preview 내부에서 정의
    let localMockWords: [Word] = [
        // 누락된 scriptId와 orderIndex 인자를 추가했습니다.
        Word(id: 1, scriptId: 1, lemma: "apple", pos: "명", meaning: "사과", orderIndex: 0),
        Word(id: 2, scriptId: 1, lemma: "run", pos: "동", meaning: "달리다", orderIndex: 1),
        Word(id: 3, scriptId: 1, lemma: "beautiful", pos: "형", meaning: "아름다운", orderIndex: 2),
        Word(id: 6, scriptId: 1, lemma: "untranslated", pos: "명", meaning: "", orderIndex: 3)
    ]
    
    // Environment 객체도 Preview 내부에서 생성
    let mockContainer = DatabaseContainer(database: AppDatabase.shared)
    
    WordkListView(
        scriptId: 1,
        words: .constant(localMockWords), // 로컬 목업 데이터 주입
        isLoading: .constant(false)
    )
    .environment(mockContainer) // 로컬 목업 컨테이너 제공
}
