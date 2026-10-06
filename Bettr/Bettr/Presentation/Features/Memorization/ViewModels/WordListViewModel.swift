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
    
    /// UI의 요청 소유권을 종료합니다. 화면이 사라질 때 뷰의 구조화된 작업도 함께 취소됩니다.
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
            try validateActiveLoad(loadID)
            let existing = try await wordExtractionService.fetchWords(for: scriptId)
            try validateActiveLoad(loadID)
            if !existing.isEmpty {
                self.words = existing
                return
            }
            try await wordExtractionService.extractAndSaveWords(for: scriptId)
            try validateActiveLoad(loadID)
            let extracted = try await wordExtractionService.fetchWords(for: scriptId)
            try validateActiveLoad(loadID)
            self.words = extracted
        } catch {
            guard activeLoadID == loadID else { return }
            handleLoadFailure(error)
        }
    }

    private func validateActiveLoad(_ loadID: UUID) throws {
        try Task.checkCancellation()
        guard activeLoadID == loadID else { throw CancellationError() }
    }

    private func handleLoadFailure(_ error: Error) {
        if Task.isCancelled || error is CancellationError || error as? AIError == .cancelled {
            errorMessage = nil
            return
        }

        AppLog.ai.error("단어 목록 불러오기 실패")
        errorMessage = (error as? AIError)?.errorDescription
            ?? "단어 목록을 불러오지 못했습니다. 다시 시도해 주세요."
    }
}
