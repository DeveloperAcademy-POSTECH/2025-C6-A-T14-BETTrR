//
//  FeedbackResultProcessor.swift
//  Bettr
//
//  Created by 길정수 on 11/14/25.
//

import Foundation


struct FeedbackResultProcessor {
    
    private let analyzer = SpeechAnalyzer()

    // MARK: - 1. 과거 피드백 (View Model 사용)
    
    /// DB에 저장된 요약(Summary) 및 상세(Details) 데이터를 바탕으로 과거의 결과 화면 모델을 재구성
    func reconstructResult(
        fromHistory summary: FeedbackSummary,
        scriptTitle: String,
        feedbackNumber: Int,
        details: [FeedbackDetail],
        sentences: [Sentence]
    ) -> FeedbackResultModel {
        
        let sentenceDiffs = self.reconstructSentenceDiffs(details: details, sentences: sentences)
        
        let filteredSentenceDiffs = self.filterIncorrectSentences(sentenceDiffs: sentenceDiffs)
        
        let resultModel = FeedbackResultModel(
            scriptTitle: scriptTitle,
            feedbackNumber: feedbackNumber,
            accuracy: summary.accuracy,
            totalRecordingTime: summary.practiceDuration,
            missingCount: summary.missingWordCount,
            extraCount: summary.addedWordCount,
            replacedCount: summary.replacedWordCount,
            filteredSentenceDiffs: filteredSentenceDiffs
        )
        
        return resultModel
    }
    
    
    // MARK: - 2. Private 헬퍼 (모두 private 유지)
    
    private func filterIncorrectSentences(sentenceDiffs: [(original: String, diffs: [WordDiff])]) -> [FeedbackResultModel.FilteredSentenceDiff] {
        return sentenceDiffs.enumerated()
            .filter { (_, data) in
                data.diffs.contains { diff in
                    switch diff {
                    case .matched: return false
                    default: return true
                    }
                }
            }
            .map { (offset, element) in
                return (index: offset, data: element)
            }
    }
    
    private func reconstructSentenceDiffs(details: [FeedbackDetail], sentences: [Sentence]) -> [(original: String, diffs: [WordDiff])] {
        
        let sortedDetails = details.sorted {
            ($0.sentenceIndex, $0.wordIndex) < ($1.sentenceIndex, $1.wordIndex)
        }
        
        let grouped = Dictionary(grouping: sortedDetails, by: { $0.sentenceIndex })
        
        return sentences.indices.map { idx in
            let original = sentences[idx].englishText
            let diffs = grouped[idx]?.map { $0.wordDiff } ?? []
            return (original: original, diffs: diffs)
        }
    }
}
