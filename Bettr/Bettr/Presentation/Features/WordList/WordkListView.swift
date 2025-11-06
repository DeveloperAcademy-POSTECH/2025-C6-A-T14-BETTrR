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
    
    @State private var words: [Word] = []
    @State private var isLoading: Bool = false
    
    var body: some View {
        VStack(alignment: .leading) {
            
            if isLoading {
                ProgressView("단어 불러오는 중...")
                    .frame(maxWidth: .infinity, alignment: .center)
            } else if words.isEmpty {
                Text("단어가 없습니다.")
                    .foregroundStyle(.secondary)
            } else {
                ScrollView {
                    VStack {
                        ForEach(Array(words.enumerated()), id: \.element.id) { index, word in
                            VStack(alignment: .leading) {
                                // Title + POS badge
                                HStack(alignment: .center, spacing: 8) {
                                    Text(word.lemma)
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundStyle(.primary)
                                        .padding(4)
                                        .padding(.trailing, 4)
                                    // POS capsule badge (한글 축약은 상위 레이어에서 처리되어 있다고 가정)
                                    Text(word.pos)
                                        .font(.system(size: 11, weight: .regular))
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 2)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(Color.clear)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 4)
                                                        .stroke(Color.indigo, lineWidth: 1)
                                                )
                                        )
                                        .foregroundStyle(.indigo)
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
                                    
                                    VStack(alignment: .leading) {
                                        ForEach(Array(parts.enumerated()), id: \.offset) { idx, item in
                                            HStack(alignment: .top) {
                                                Text("\(idx + 1).")
                                                    .font(.callout.weight(.semibold))
                                                    .foregroundStyle(.secondary)
                                                    .frame(width: 18, alignment: .trailing)
                                                Text(item)
                                                    .font(.callout)
                                                    .foregroundStyle(.primary)
                                                    .multilineTextAlignment(.leading)
                                            }
                                        }
                                    }
                                }
                            }
                            
                            if index != words.count - 1 {
                                Divider()
                            }
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
            
            Spacer()
        }
        .padding(.top, 40)
        .padding(.leading, 36)
        .frame(maxWidth: 360, maxHeight: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 35)
                .fill(.regularMaterial)
        )
        .task {
            await loadWords()
        }
//        .translationTask(translationConfig) { session in
//            guard !pendingLemmas.isEmpty else { return }
//            
//            var translations: [String: String] = [:]
//            
//            do {
//                for lemma in pendingLemmas {
//                    let response = try await session.translate(lemma)
//                    translations[lemma] = response.targetText
//                    
//                    // 즉시 UI 업데이트
//                    if let idx = words.firstIndex(where: { $0.lemma == lemma }) {
//                        words[idx].meaning = response.targetText
//                    }
//                }
//                
//                // DB에도 저장
//                try container.wordExtractionService.updateWordMeanings(
//                    for: scriptId,
//                    translations: translations
//                )
//            } catch {
//                print("⚠️ 번역 중 오류: \(error.localizedDescription)")
//            }
//            
//            translationConfig = nil
//            pendingLemmas.removeAll()
//        }
    }
    
    private func loadWords() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // DB에서 단어 불러오기
            let fetchedWords = try container.wordExtractionService.fetchWords(for: scriptId)
            
            self.words = fetchedWords
            
//            // 번역이 안 된 단어들 번역하기
//            let untranslated = words.filter { $0.meaning.isEmpty }
//            if !untranslated.isEmpty {
//                self.pendingLemmas = Array(untranslated.map { $0.lemma }.prefix(TranslationHelper.maxTranslationCount))
//                
//                if !pendingLemmas.isEmpty {
//                    self.translationConfig = TranslationHelper.createConfiguration()
//                }
//            }
        } catch {
            print("⚠️ 단어 불러오기 실패: \(error.localizedDescription)")
        }
    }
}

#Preview {
    WordkListView(scriptId: 1)
        .environment(DatabaseContainer(database: AppDatabase.shared))
}
