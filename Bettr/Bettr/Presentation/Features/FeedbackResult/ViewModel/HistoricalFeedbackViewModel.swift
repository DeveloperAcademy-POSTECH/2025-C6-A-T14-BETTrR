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
        
        self.accuracy = summary.accuracy
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
            async let scriptTask = scriptManagementService.fetchScriptWithSentences(id: summary.scriptId)
            async let detailsTask = scriptManagementService.fetchFeedbackDetails(forFeedbackSummaryId: summaryId)
            
            let originalScript = try await scriptTask
            let feedbackDetails = try await detailsTask // (DB에 저장된 '오류' 목록)
            
            
            
            let originalSentences = originalScript?.sentences ?? []
            
            // (sentenceIndex, wordIndex)를 키로 하는 FeedbackDetail 맵 생성
            var feedbackDetailMap: [String: FeedbackDetail] = [:]
            for detail in feedbackDetails {
                let key = "\(detail.sentenceIndex)-\(detail.wordIndex)"
                feedbackDetailMap[key] = detail
            }
            
            var reconstructedSentenceDiffs: [(original: String, diffs: [WordDiff])] = []
            
            for (sIdx, sentence) in originalSentences.enumerated() {
                let originalWords = analyzer.normalize(sentence.englishText)
                var sentenceDiffs: [WordDiff] = []
                
                // Create a temporary array to hold the diffs, initially filled with matched words
                var tempSentenceDiffs: [WordDiff] = []
                for word in originalWords {
                    tempSentenceDiffs.append(.matched(word: word))
                }
                
                // Apply errors (missing, replaced)
                for (wIdx, word) in originalWords.enumerated() {
                    let key = "\(sIdx)-\(wIdx)"
                    if let detail = feedbackDetailMap[key] {
                        // Only apply if it's a missing or replaced word
                        switch detail.wordDiff {
                        case .missing, .replaced:
                            // Replace the matched word with the error
                            if wIdx < tempSentenceDiffs.count {
                                tempSentenceDiffs[wIdx] = detail.wordDiff
                            }
                        default:
                            break // Extra words are handled separately
                        }
                    }
                }
                
                // Insert extra words
                let extraDetails = feedbackDetailMap.values.filter { detail in
                    detail.sentenceIndex == sIdx && { if case .extra = detail.wordDiff { return true } else { return false } }()
                }.sorted { $0.wordIndex < $1.wordIndex } // Sort by wordIndex to insert in order
                
                var offset = 0 // To account for insertions
                for extraDetail in extraDetails {
                    let insertIndex = extraDetail.wordIndex + offset // wordIndex is the index of the original word *before* the extra word
                    
                    // Ensure insertIndex is within bounds
                    if insertIndex <= tempSentenceDiffs.count {
                        tempSentenceDiffs.insert(extraDetail.wordDiff, at: insertIndex)
                        offset += 1
                    } else {
                        tempSentenceDiffs.append(extraDetail.wordDiff) // Append if index is out of bounds (e.g., at the very end)
                    }
                }
                
                sentenceDiffs = tempSentenceDiffs
                reconstructedSentenceDiffs.append((original: sentence.englishText, diffs: sentenceDiffs))
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
