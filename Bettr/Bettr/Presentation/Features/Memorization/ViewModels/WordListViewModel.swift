//
//  WordListViewModel.swift
//  Bettr
//
//  Created by 길정수 on 11/13/25.
//

import Foundation

@Observable
final class WordListViewModel {
    // MARK: - Dependencies
    let scriptId: Int64
    let wordExtractionService: WordExtractionService
    
    // MARK: - State
    var words: [Word] = []
    var isLoading: Bool = false
    var errorMessage: String? = nil

    init(scriptId: Int64, wordExtractionService: WordExtractionService) {
        self.scriptId = scriptId
        self.wordExtractionService = wordExtractionService
    }
    
    @MainActor
    func loadWords() async {
        if !words.isEmpty { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let existing = try await wordExtractionService.fetchWords(for: scriptId)
            if !existing.isEmpty {
                self.words = existing
                return
            }
            try await wordExtractionService.extractAndSaveWords(for: scriptId)
            self.words = try await wordExtractionService.fetchWords(for: scriptId)
            
        } catch {
            print("🔥 단어 추출 중 오류 발생:", error.localizedDescription)
            self.errorMessage = error.localizedDescription
        }
    }
}
