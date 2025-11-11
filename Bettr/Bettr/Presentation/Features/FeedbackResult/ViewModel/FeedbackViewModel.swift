//
//  FeedbackViewModel.swift
//  Bettr
//
//  Created by 길정수 on 11/4/25.
//

import Foundation
import SwiftUI

@Observable
@MainActor
class FeedbackViewModel {
    
    // MARK: - Published Properties (UI용)
    

    
    /// DB에 저장 중인지 여부 (예: 로딩 스피너 표시용)
    var isSaving = false
    
    /// 저장 실패 시 에러 (예: 에러 메시지 표시용)
    var saveError: Error?
    
    // MARK: - View-Specific Logic Properties
    
    /// 문장별로 청크(chunk)된 Diff 배열
    let sentenceDiffs: [(original: String, diffs: [WordDiff])]
    
    /// 누락된 단어(Missing) 개수
    let missingCount: Int
    
    /// 추가된 단어(Extra) 개수
    let extraCount: Int
    
    /// 대체된 단어(Replaced) 개수
    let replacedCount: Int

    /// 정확도 (Computed Property)
    var accuracy: Double {
        let totalOriginalWords = sentences.reduce(0) { $0 + analyzer.normalize($1).count }
        let matchedCount = sentenceDiffs.reduce(0) { total, sentenceData in
            total + sentenceData.diffs.filter {
                if case .matched = $0 { return true }
                return false
            }.count
        }
        return totalOriginalWords == 0 ? 0 : Double(matchedCount) / Double(totalOriginalWords)
    }
    
    /// 원본 인덱스를 유지하면서 틀린 문장만 필터링한 배열 (Computed Property)
    var filteredSentenceDiffs: [(index: Int, data: (original: String, diffs: [WordDiff]))] {
        sentenceDiffs.enumerated().filter { (index, data) in
            // data.diffs (diffs 배열)에 .matched 외의 것이 하나라도 있는지 확인
            data.diffs.contains { diff in
                switch diff {
                case .matched:
                    return false // 에러가 아님 (계속 탐색)
                case .missing, .extra, .replaced:
                    return true // 에러 발견 (이 문장을 포함)
                }
            }
        }
        .map { (offset, element) in
            // (offset, element) 튜플을 (index, data) 튜플로 변환
            return (index: offset, data: element)
        }
    }
    
    
    // MARK: - Private Properties
    private let scriptId: Int64
    private let sentences: [String]
    let practiceDuration: Double
    private let scriptManagementService: ScriptManagementServiceProtocol
    private let analyzer = SpeechAnalyzer()
    
    // MARK: - Initializer
    
    init(
        scriptId: Int64,
        diffs: [WordDiff], // New parameter
        sentences: [String],
        practiceDuration: Double, // Add this
        scriptManagementService: ScriptManagementServiceProtocol
    ) {
        self.scriptId = scriptId
        self.sentences = sentences
        self.practiceDuration = practiceDuration // Assign this
        self.scriptManagementService = scriptManagementService
        
        var tempDiffs = diffs // Use the new diffs parameter
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
        self.sentenceDiffs = chunkedResult

        self.missingCount = diffs.filter { // Use the new diffs parameter
            if case .missing = $0 { return true }; return false
        }.count
        self.extraCount = diffs.filter { // Use the new diffs parameter
            if case .extra = $0 { return true }; return false
        }.count
        self.replacedCount = diffs.filter { // Use the new diffs parameter
            if case .replaced = $0 { return true }; return false
        }.count
    }
    
    
    // MARK: - Core Logic (DB Save)
    
    func saveFeedbackResult(practiceDuration: Double) async {
        isSaving = true
        saveError = nil
        
        // --- 데이터 변환 로직 (빠르므로 메인 스레드에서 수행) ---
        var detailsData: [(
            wordDiff: WordDiff,
            originalText: String?,
            sentenceIndex: Int,
            wordIndex: Int
        )] = []
        
        // (카운트는 init에서 이미 계산 완료)
        
        // `feedback.diffs`는 전체 스크립트에 대한 WordDiff 배열이므로,
        // 각 WordDiff에 해당하는 sentenceIndex와 wordIndex를 찾아야 합니다.
        // 이를 위해 `sentenceDiffs`를 활용합니다.
        var globalWordIndex = 0
        for (sIdx, sentenceData) in sentenceDiffs.enumerated() {
            for (wIdx, diff) in sentenceData.diffs.enumerated() {
                switch diff {
                case .matched:
                    break // 에러 아님
                    
                case .missing(let expected):
                    detailsData.append((
                        wordDiff: diff,
                        originalText: expected,
                        sentenceIndex: sIdx,
                        wordIndex: wIdx
                    ))
                    
                case .extra(let actual):
                    detailsData.append((
                        wordDiff: diff,
                        originalText: nil,
                        sentenceIndex: sIdx,
                        wordIndex: wIdx
                    ))
                    
                case .replaced(let expected, let actual):
                    detailsData.append((
                        wordDiff: diff,
                        originalText: expected,
                        sentenceIndex: sIdx,
                        wordIndex: wIdx
                    ))
                }
                globalWordIndex += 1
            }
        }
        
        // --- 서비스 호출 (DB 작업) ---
        do {
            // Task.detached를 사용해 DB 작업을 백그라운드 스레드로 보냄
            let summary = try await Task.detached {
                try await self.scriptManagementService.createFeedbackSummary(
                    scriptId: self.scriptId,
                    accuracy: self.accuracy,
                    missingWordCount: self.missingCount,
                    addedWordCount: self.extraCount,
                    replacedWordCount: self.replacedCount,
                    practiceDuration: practiceDuration,
                    feedbackDetailsData: detailsData
                )
            }.value // .value를 사용해 백그라운드 작업이 끝나고 결과를 받음

            // 성공: (await 이후 다시 @MainActor로 복귀됨)
            print("피드백 저장 성공. Summary ID: \(summary.id ?? -1)")
            isSaving = false
            
        } catch {
            // 실패: (await 이후 다시 @MainActor로 복귀됨)
            print("피드백 저장 실패: \(error)")
            saveError = error
            isSaving = false
        }
    }
}

