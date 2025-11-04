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
    
    /// SpeechRecognizer로부터 받은 원본 피드백 결과
    let feedbackResult: FeedbackResultModel?
    
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
    private let sentences: [String] // 청크 로직을 위해 'sentences'도 VM이 소유
    private let scriptManagementService: ScriptManagementServiceProtocol
    private let analyzer = SpeechAnalyzer() // 청크 로직을 위해 인스턴스 소유
    
    
    // MARK: - Initializer
    
    init(
        scriptId: Int64,
        feedbackResult: FeedbackResultModel?,
        sentences: [String],
        scriptManagementService: ScriptManagementServiceProtocol
    ) {
        self.scriptId = scriptId
        self.feedbackResult = feedbackResult
        self.sentences = sentences
        self.scriptManagementService = scriptManagementService
        
        var tempDiffs = feedbackResult?.diffs ?? []
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

        let diffs = feedbackResult?.diffs ?? []
        self.missingCount = diffs.filter {
            if case .missing = $0 { return true }; return false
        }.count
        self.extraCount = diffs.filter {
            if case .extra = $0 { return true }; return false
        }.count
        self.replacedCount = diffs.filter {
            if case .replaced = $0 { return true }; return false
        }.count
    }
    
    
    // MARK: - Core Logic (DB Save)
    
    func saveFeedbackResult() async {
        guard let feedback = feedbackResult else {
            print("저장할 피드백 결과(feedbackResult)가 nil입니다.")
            return
        }
        
        isSaving = true
        saveError = nil
        
        // --- 데이터 변환 로직 (빠르므로 메인 스레드에서 수행) ---
        var detailsData: [(
            errorType: FeedbackErrorType,
            originalText: String?,
            spokenText: String?,
            startTime: Double,
            endTime: Double
        )] = []
        
        // (카운트는 init에서 이미 계산 완료)
        
        for diff in feedback.diffs {
            switch diff {
            case .matched:
                break // 에러 아님
                
            case .missing(let expected):
                detailsData.append((.missingWord, expected, nil, 0.0, 0.0))
                
            case .extra(let actual):
                detailsData.append((.addedWord, nil, actual, 0.0, 0.0))
                
            case .replaced(let expected, let actual):
                detailsData.append((.replacedWord, expected, actual, 0.0, 0.0))
            }
        }
        
        // --- 서비스 호출 (DB 작업) ---
        do {
            // Task.detached를 사용해 DB 작업을 백그라운드 스레드로 보냄
            let summary = try await Task.detached {
                try await self.scriptManagementService.createFeedbackSummary(
                    scriptId: self.scriptId,
                    totalScore: feedback.accuracy,
                    missingWordCount: self.missingCount,
                    addedWordCount: self.extraCount,
                    replacedWordCount: self.replacedCount,
                    practiceDuration: feedback.totalRecordingTime,
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

