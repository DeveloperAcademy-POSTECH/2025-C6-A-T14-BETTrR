//
//  FeedbackResultProcessor.swift
//  Bettr
//
//  Created by 길정수 on 11/14/25.
//

import Foundation

struct FeedbackResultProcessor {
    
    private let analyzer = SpeechAnalyzer()
    
    // MARK: - 과거 피드백 재구성
    
    /// 저장된 피드백 기록(Summary, Details)과 원문 스크립트 정보를 사용하여 결과 화면 표시를 위한 모델을 재구성
    ///
    /// - Parameters:
    ///   - summary: DB에 저장된 전체 요약 정보 (정확도, 소요 시간 등)
    ///   - scriptTitle: 스크립트 제목
    ///   - feedbackNumber: 피드백 회차 번호
    ///   - details: DB에 저장된 단어별 상세 분석 결과 리스트
    ///   - sentences: 원문 스크립트의 문장 리스트
    /// - Returns: 결과 화면 UI 바인딩에 사용되는 `FeedbackResultModel`
    func reconstructResult(
        fromHistory summary: FeedbackSummary,
        scriptTitle: String,
        feedbackNumber: Int,
        details: [FeedbackDetail],
        sentences: [Sentence]
    ) -> FeedbackResultModel {
        
        let sentenceDiffs = self.reconstructSentenceDiffs(details: details, sentences: sentences)
        
        let filteredSentenceDiffs = self.filterIncorrectSentences(sentenceDiffs: sentenceDiffs)
        
        return FeedbackResultModel(
            scriptTitle: scriptTitle,
            feedbackNumber: feedbackNumber,
            accuracy: summary.accuracy,
            totalRecordingTime: summary.practiceDuration,
            missingCount: summary.missingWordCount,
            extraCount: summary.addedWordCount,
            replacedCount: summary.replacedWordCount,
            filteredSentenceDiffs: filteredSentenceDiffs
        )
    }
    
    // MARK: - Private Helpers
    
    /// 전체 문장 분석 결과 중, 오류(Missing, Extra, Replaced 등)가 포함된 문장만 필터링
    /// - Parameter sentenceDiffs: 전체 문장의 분석 결과 튜플 리스트
    /// - Returns: 오류가 포함된 문장의 인덱스와 데이터만 추려낸 리스트
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
    
    /// DB에 저장된 단어별 상세 데이터(`FeedbackDetail`)를 문장 단위로 그룹화하여 UI용 Diff 데이터로 변환
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
