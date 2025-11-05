//
//  HistoricalFeedbackViewModel.swift
//  Bettr
//
//  Created by 길정수 on 11/5/25.
//

import Foundation
import SwiftUI

@Observable
@MainActor
class HistoricalFeedbackViewModel {
    
    // MARK: - UI State
    var isLoading = true
    var loadError: Error?
    
    // MARK: - Display Properties
    var accuracy: Double = 0
    var totalRecordingTime: TimeInterval = 0
    var missingCount: Int = 0
    var extraCount: Int = 0
    var replacedCount: Int = 0
    
    var filteredSentenceDiffs: [(index: Int, data: (original: String, diffs: [WordDiff]))] = []
    var hasSentences: Bool = false
    
    // MARK: - Dependencies
    private let summary: FeedbackSummary
    private let scriptManagementService: ScriptManagementServiceProtocol
    private let analyzer = SpeechAnalyzer()
    
    init(
        summary: FeedbackSummary,
        scriptManagementService: ScriptManagementServiceProtocol
    ) {
        self.summary = summary
        self.scriptManagementService = scriptManagementService
        
        self.accuracy = summary.totalScore
        self.totalRecordingTime = summary.practiceDuration
        self.missingCount = summary.missingWordCount
        self.extraCount = summary.addedWordCount
        self.replacedCount = summary.replacedWordCount
    }
    
    func loadFeedbackData() async {
        guard let summaryId = summary.id else {
            // (방어 코드) Summary 객체에 ID가 없는 비정상적인 경우
            loadError = NSError(domain: "HistoricalFeedbackViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "FeedbackSummary ID가 없습니다."])
            isLoading = false
            return
        }
        
        self.isLoading = true
        self.loadError = nil
        
        do {
            // --- 1. DB에서 상세 데이터 병렬 로드 ---
            // 'scriptId'로 원본 스크립트를, 'summaryId'로 오류 내역을 동시에 가져옵니다.
            async let scriptTask = scriptManagementService.fetchScriptWithSentences(id: summary.scriptId)
            async let detailsTask = scriptManagementService.fetchFeedbackDetails(forFeedbackSummaryId: summaryId)
            
            let originalScript = try await scriptTask
            let feedbackDetails = try await detailsTask // (DB에 저장된 '오류' 목록)
            
            let originalSentences = originalScript?.sentences ?? []
            
            var detailQueue = feedbackDetails // 오류 목록을 큐처럼 사용
            var reconstructedSentenceDiffs: [(original: String, diffs: [WordDiff])] = []
            
            for sentence in originalSentences {
                let originalWords = analyzer.normalize(sentence.englishText)
                var sentenceDiffs: [WordDiff] = []
                
                // 2.1. 원본 문장의 단어를 하나씩 순회
                for word in originalWords {
                    
                    // 2.2. 현재 단어(word)와 일치하는 '오류'가 큐의 맨 앞에 있는지 확인
                    // (단, .addedWord는 originalText가 nil이므로 이 조건에 걸리지 않음)
                    if let nextError = detailQueue.first, nextError.originalText == word {
                        // 일치하는 오류 발견 (.missing 또는 .replaced)
                        _ = detailQueue.removeFirst() // 큐에서 해당 오류 제거
                        
                        switch nextError.errorType {
                        case .missingWord:
                            sentenceDiffs.append(.missing(expected: word))
                        case .replacedWord:
                            sentenceDiffs.append(.replaced(expected: word, actual: nextError.spokenText ?? "?"))
                        default:
                            // .addedWord 이거나 알 수 없는 오류 -> 일단 .matched 처리 (예외)
                                                 sentenceDiffs.append(.matched(word: word))
                        }
                        
                    } else {
                        // 2.3. 일치하는 오류 없음 -> '.matched'로 복원
                        sentenceDiffs.append(.matched(word: word))
                    }
                } // (단어 루프 끝)
                
                // 2.4. 문장의 끝에 .addedWord(.extra)가 있는지 확인
                // (errorType == .addedWord 이고 originalText == nil 인 경우)
                while let nextError = detailQueue.first, nextError.errorType == .addedWord {
                    _ = detailQueue.removeFirst() // 큐에서 .addedWord 제거
                    sentenceDiffs.append(.extra(actual: nextError.spokenText ?? "?"))
                }
                
                reconstructedSentenceDiffs.append((original: sentence.englishText, diffs: sentenceDiffs))

            } // (문장 루프 끝)
            
            // 2.5. (엣지 케이스) 모든 문장이 끝난 후에도 .addedWord가 큐에 남아있다면,
            // 마지막 문장의 끝에 모두 추가합니다.
            if var lastSentenceDiffs = reconstructedSentenceDiffs.popLast() {
                while let nextError = detailQueue.first, nextError.errorType == .addedWord {
                    _ = detailQueue.removeFirst()
                    lastSentenceDiffs.diffs.append(.extra(actual: nextError.spokenText ?? "?"))
                }
                reconstructedSentenceDiffs.append(lastSentenceDiffs)
            }
            
            
            // --- 3. 가공된 데이터를 UI가 사용할 형태로 필터링 ---
            self.hasSentences = !reconstructedSentenceDiffs.isEmpty
            
            // '.matched' 외의 오류가 있는 문장만 필터링
            self.filteredSentenceDiffs = reconstructedSentenceDiffs.enumerated()
                .filter { (index, data) in
                    data.diffs.contains { diff in
                        switch diff {
                        case .matched: return false // 오류 아님
                        default: return true // 오류(.missing, .extra, .replaced) 발견
                        }
                    }
                }
                .map { (offset, element) in
                    // (index: 원본 인덱스, data: {original, diffs}) 형태로 변환
                    return (index: offset, data: element)
                }
            
            self.isLoading = false // 로딩 완료
            
        } catch {
            // --- 4. 에러 처리 ---
            print("피드백 상세 정보 불러오기 실패: \(error)")
            self.loadError = error
            self.isLoading = false
        }
    }
}
