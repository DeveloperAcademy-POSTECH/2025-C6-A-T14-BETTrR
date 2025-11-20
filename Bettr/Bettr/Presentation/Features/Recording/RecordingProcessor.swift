//
//  RecordingProcessor.swift
//  Bettr
//
//  Created by 길정수 on 11/21/25.
//

import Foundation

// MARK: - DB 저장을 위한 데이터 구조

struct FeedbackDetailParams {
    let wordDiff: WordDiff
    let originalText: String?
    let sentenceIndex: Int
    let wordIndex: Int
}

struct SummarySaveParams {
    let dbDetails: [FeedbackDetailParams]
    let accuracy: Double
    let missingCount: Int
    let extraCount: Int
    let replacedCount: Int
    let practiceDuration: Double
}

/// 녹음 분석 결과를 DB 저장에 필요한 파라미터 및 통계로 변환하는 프로세서
struct RecordingProcessor {
    
    private let analyzer: SpeechAnalyzer // 의존성 주입
    
    init(analyzer: SpeechAnalyzer) {
        self.analyzer = analyzer
    }
    
    
    // MARK: - 1. 실시간 분석 결과 -> 저장 파라미터 및 요약 통계 생성
    
    /// 실시간 음성 분석 결과를 바탕으로 DB 저장에 필요한 파라미터와 요약 통계를 생성합니다.
    func createSummaryStats(
        fromLiveAnalysis diffs: [WordDiff],
        sentences: [String],
        practiceDuration: Double
    ) -> SummarySaveParams {
        
        let sentenceDiffs = self.groupDiffsBySentence(diffs: diffs, sentences: sentences)
        
        // 통계 계산
        let (missing, extra, replaced) = self.countErrors(from: diffs)
        let accuracy = self.calculateAccuracy(sentences: sentences, sentenceDiffs: sentenceDiffs)
        
        // DB 상세 파라미터 생성
        let dbDetails = self.createDetailParams(sentenceDiffs: sentenceDiffs)
        
        return SummarySaveParams(
            dbDetails: dbDetails,
            accuracy: accuracy,
            missingCount: missing,
            extraCount: extra,
            replacedCount: replaced,
            practiceDuration: practiceDuration
        )
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
}
