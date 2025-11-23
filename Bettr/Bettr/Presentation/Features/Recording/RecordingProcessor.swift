//
//  RecordingProcessor.swift
//  Bettr
//
//  Created by 길정수 on 11/21/25.
//

import Foundation

/// 녹음 분석 결과를 DB 저장에 필요한 파라미터 및 통계로 변환하는 프로세서
struct RecordingProcessor {
    
    private let analyzer: SpeechAnalyzer // 의존성 주입
    
    init(analyzer: SpeechAnalyzer) {
        self.analyzer = analyzer
    }
    
    // MARK: - Public Methods
    
    /// 실시간 음성 분석 결과(WordDiff 배열)와 문장 정보를 바탕으로, DB 저장용 파라미터 및 요약 통계 객체를 생성
    ///  - Parameters:
    ///   - diffs: SpeechAnalyzer를 통해 분석된 단어별 차이 정보 배열
    ///   - sentences: 원본 스크립트 문장 배열
    ///   - practiceDuration: 총 녹음 시간
    /// - Returns: DB 저장에 필요한 상세 정보와 요약 통계가 담긴 `SummarySaveParams`
    func createSummaryStats(
        fromLiveAnalysis diffs: [WordDiff],
        sentences: [String],
        practiceDuration: Double
    ) -> SummarySaveParams {
        
        let sentenceDiffs = self.groupDiffsBySentence(diffs: diffs, sentences: sentences)
        let (missing, extra, replaced) = self.countErrors(from: diffs)
        let accuracy = self.calculateAccuracy(sentences: sentences, sentenceDiffs: sentenceDiffs)
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
    
    // MARK: - Private Helper Methods
    
    /// 일렬로 나열된 전체 단어 분석 결과(`WordDiff`)를 원본 문장 구조에 맞춰 그룹화
    /// - Returns: (원본 문장, 해당 문장에 속한 WordDiff 배열)의 튜플 배열
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
    
    /// 전체 분석 결과에서 에러 유형별(누락, 추가, 대체) 개수를 집계
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
    
    /// 원본 단어 수 대비 매칭된 단어 수를 기반으로 정확도를 계산
    /// - Returns: 0.0 ~ 1.0 사이의 Double 값
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
    
    /// 문장별로 그룹화된 분석 결과를 DB 저장을 위한 `FeedbackDetailParams` 배열로 변환
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
