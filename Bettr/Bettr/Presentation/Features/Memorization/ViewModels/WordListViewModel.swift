//
//  WordListViewModel.swift
//  Bettr
//
//  Created by 길정수 on 11/13/25.
//

import Foundation

@Observable
@MainActor
final class WordListViewModel {
    // MARK: - Dependencies
    let scriptId: Int64
    let wordExtractionService: any WordExtractionServicing
    
    // MARK: - State
    var words: [Word] = []
    var isLoading: Bool = false
    var errorMessage: String?
    private var activeLoadID: UUID?

    init(scriptId: Int64, wordExtractionService: any WordExtractionServicing) {
        self.scriptId = scriptId
        self.wordExtractionService = wordExtractionService
    }
    
    /// Ends UI ownership; the view also cancels its structured task on disappearance.
    func cancelLoading() {
        activeLoadID = nil
        isLoading = false
    }

    func loadWords() async {
        if isLoading || !words.isEmpty { return }
        
        let loadID = UUID()
        activeLoadID = loadID
        isLoading = true
        errorMessage = nil
        defer {
            if activeLoadID == loadID {
                activeLoadID = nil
                isLoading = false
            }
        }
        
        do {
            try Task.checkCancellation()
            let existing = try await wordExtractionService.fetchWords(for: scriptId)
            try Task.checkCancellation()
            guard activeLoadID == loadID else { return }
            if !existing.isEmpty {
                self.words = existing
                return
            }
            try await wordExtractionService.extractAndSaveWords(for: scriptId)
            try Task.checkCancellation()
            guard activeLoadID == loadID else { return }
            let extracted = try await wordExtractionService.fetchWords(for: scriptId)
            try Task.checkCancellation()
            guard activeLoadID == loadID else { return }
            self.words = extracted
            
        } catch is CancellationError {
            guard activeLoadID == loadID else { return }
            errorMessage = nil
        } catch AIError.cancelled {
            guard activeLoadID == loadID else { return }
            errorMessage = nil
        } catch let error as AIError {
            guard activeLoadID == loadID else { return }
            AppLog.ai.error("단어 목록 불러오기 실패")
            errorMessage = Task.isCancelled ? nil : error.errorDescription
        } catch {
            guard activeLoadID == loadID else { return }
            AppLog.ai.error("단어 목록 불러오기 실패")
            errorMessage = Task.isCancelled ? nil : "단어 목록을 불러오지 못했습니다. 다시 시도해 주세요."
        }
    }
}
