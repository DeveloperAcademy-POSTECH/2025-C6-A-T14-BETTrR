//
//  FeedbackResultProcessor.swift
//  Bettr
//
//  Created by 길정수 on 11/14/25.
//

import Foundation

struct FeedbackResultProcessor {
    
    private let analyzer = SpeechAnalyzer()
    
    // MARK: - 1. 실시간 분석 (FeedbackViewModel용)
    
    /// 실시간 음성 분석이 완료된 후, 결과 화면에 필요한 모델과 DB에 저장할 파라미터를 생성
    func generateResult(
        fromLiveAnalysis scriptTitle: String,
        currentFeedbackCount: Int,
        diffs: [WordDiff],
        sentences: [String],
        practiceDuration: Double
    ) -> (resultModel: FeedbackResultModel, detailParams: [FeedbackDetailParams]) {
        
        let sentenceDiffs = self.groupDiffsBySentence(diffs: diffs, sentences: sentences)
        
        let (missing, extra, replaced) = self.countErrors(from: diffs)
        let accuracy = self.calculateAccuracy(sentences: sentences, sentenceDiffs: sentenceDiffs)
        
        let filteredSentenceDiffs = self.filterIncorrectSentences(sentenceDiffs: sentenceDiffs)
        
        let resultModel = FeedbackResultModel(
            scriptTitle: scriptTitle,
            feedbackNumber: currentFeedbackCount + 1,
            accuracy: accuracy,
            totalRecordingTime: practiceDuration,
            missingCount: missing,
            extraCount: extra,
            replacedCount: replaced,
            filteredSentenceDiffs: filteredSentenceDiffs
        )
        
        let dbParams = self.createDetailParams(sentenceDiffs: sentenceDiffs)
        
        return (resultModel, dbParams)
    }
    
    // MARK: - 2. 과거 피드백 (HistoricalFeedbackViewModel용)
    
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
    
    
    // MARK: - 3. Private 헬퍼
    
    private func filterIncorrectSentences(sentenceDiffs: [(original: String, diffs: [WordDiff])]) -> [FeedbackResultModel.FilteredSentenceDiff] {
        return sentenceDiffs.enumerated()
            .filter { (index, data) in
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
    
    /// 단어별 'WordDiff' 배열을 문장별로 다시 그룹화
    private func groupDiffsBySentence(diffs: [WordDiff], sentences: [String]) -> [(original: String, diffs: [WordDiff])] {
        var tempDiffs = diffs
        var chunkedResult: [(original: String, diffs: [WordDiff])] = []
        
        for sentence in sentences {
            let wordCount = analyzer.normalize(sentence).count
            var chunk: [WordDiff] = []
            var wordsTaken = 0
            
            while wordsTaken < wordCount && !tempDiffs.isEmpty {
                let diff = tempDiffs.removeFirst()
                chunk.append(diff)
                
                switch diff {
                case .matched, .missing, .replaced:
                    wordsTaken += 1
                case .extra:
                    break
                }
            }
            
            while let nextDiff = tempDiffs.first, case .extra = nextDiff {
                chunk.append(tempDiffs.removeFirst())
            }
            chunkedResult.append((original: sentence, diffs: chunk))
        }
        
        if !tempDiffs.isEmpty {
            if chunkedResult.isEmpty {
                chunkedResult.append((original: "", diffs: tempDiffs))
            } else {
                chunkedResult[chunkedResult.count - 1].diffs.append(contentsOf: tempDiffs)
            }
        }
        return chunkedResult
    }
    
    private func countErrors(from diffs: [WordDiff]) -> (missing: Int, extra: Int, replaced: Int) {
        diffs.reduce(into: (missing: 0, extra: 0, replaced: 0)) { result, diff in
            
            switch diff {
            case .missing:
                result.missing += 1
            case .extra:
                result.extra += 1
            case .replaced:
                result.replaced += 1
            case .matched:
                break
            }
        }
    }
    
    private func calculateAccuracy(sentences: [String], sentenceDiffs: [(original: String, diffs: [WordDiff])]) -> Double {
        let totalOriginalWords = sentences.reduce(0) { $0 + analyzer.normalize($1).count }
        
        let matchedCount = sentenceDiffs.reduce(0) { total, sentenceData in
            total + sentenceData.diffs.filter {
                if case .matched = $0 { return true }
                return false
            }.count
        }
        return totalOriginalWords == 0 ? 0 : Double(matchedCount) / Double(totalOriginalWords)
    }
    
    /// DB에 저장할 'FeedbackDetail' 레코드를 생성하기 위한 파라미터 배열을 생성
    private func createDetailParams(sentenceDiffs: [(original: String, diffs: [WordDiff])]) -> [FeedbackDetailParams] {
        var detailsData: [FeedbackDetailParams] = []
        for (sIdx, sentenceData) in sentenceDiffs.enumerated() {
            for (wIdx, diff) in sentenceData.diffs.enumerated() {
                
                let originalWord = diff.originalText
                
                detailsData.append(FeedbackDetailParams(
                    wordDiff: diff,
                    originalText: originalWord,
                    sentenceIndex: sIdx,
                    wordIndex: wIdx
                ))
            }
        }
        return detailsData
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
