//
//  FeedbackViewModel.swift
//  Bettr
//
//  Created by 길정수 on 11/4/25.
//

import Foundation
import SwiftUI

/// 실시간 음성 분석이 완료된 직후의 피드백 결과를 표시하고,
/// 해당 결과를 데이터베이스에 저장하는 역할을 담당하는 뷰모델
@Observable
@MainActor
class FeedbackViewModel {
    
    // MARK: - 1. UI State Properties
    
    /// DB에 피드백을 저장 중인지 여부 (예: 로딩 스피너 표시용)
    var isSaving = false
    
    /// 피드백 저장 실패 시 발생하는 에러 (예: 에러 메시지 표시용)
    var saveError: Error?
    
    // MARK: - 2. View-Specific Logic Properties
    
    /// 원본 문장별로 분할된(re-chunked) `WordDiff` 배열입니다.
    /// `[(original: "원본 문장", diffs: [분석 결과 WordDiff 배열])]` 형태입니다.
    let sentenceDiffs: [(original: String, diffs: [WordDiff])]
    
    /// 전체 스크립트에서 누락된 단어(Missing)의 총 개수
    let missingCount: Int
    
    /// 전체 스크립트에서 추가된 단어(Extra)의 총 개수
    let extraCount: Int
    
    /// 전체 스크립트에서 대체된 단어(Replaced)의 총 개수
    let replacedCount: Int
    
    /// 연습에 소요된 총 시간 (초)
    let practiceDuration: Double

    // MARK: - 3. Computed Properties
    
    /// 전체 정확도를 계산하는 연산 프로퍼티입니다.
    /// (총 원본 단어 수 대비 .matched 단어 수)
    var accuracy: Double {
        // 1. 원본 문장들을 정규화하여 총 단어 수 계산
        let totalOriginalWords = sentences.reduce(0) { $0 + analyzer.normalize($1).count }
        
        // 2. sentenceDiffs에서 .matched 케이스의 총 개수 계산
        let matchedCount = sentenceDiffs.reduce(0) { total, sentenceData in
            total + sentenceData.diffs.filter {
                if case .matched = $0 { return true }
                return false
            }.count
        }
        
        // 3. 정확도 계산 (0으로 나누기 방지)
        return totalOriginalWords == 0 ? 0 : Double(matchedCount) / Double(totalOriginalWords)
    }
    
    /// 뷰에 표시할 "틀린 문장" 목록을 필터링하는 연산 프로퍼티입니다.
    /// - 중요: 오류(.matched 외)가 하나라도 포함된 문장의 *전체* `diffs` 배열을 반환합니다.
    /// - 형태: `[(index: 원본 문장 인덱스, data: (original: 원본 문장, diffs: [WordDiff] 배열))]`
    var filteredSentenceDiffs: [(index: Int, data: (original: String, diffs: [WordDiff]))] {
        sentenceDiffs.enumerated()
            // 1. .matched 외의 오류가 하나라도 있는지 확인하여 문장 필터링
            .filter { (index, data) in
                data.diffs.contains { diff in
                    switch diff {
                    case .matched:
                        return false // 오류 아님 (계속 탐색)
                    case .missing, .extra, .replaced:
                        return true // 오류 발견! (이 문장을 포함시킴)
                    }
                }
            }
            // 2. 필터링된 문장의 *원본 데이터*를 뷰가 사용하기 쉬운 형태로 매핑
            .map { (offset, element) in
                // element.data.diffs는 .matched를 포함한 *전체* diffs 배열입니다.
                return (index: offset, data: element)
            }
    }
    
    // MARK: - 4. Private Properties & Dependencies
    
    /// 피드백이 저장될 대상 스크립트의 ID
    private let scriptId: Int64
    
    /// `SpeechAnalyzer`에서 사용된 원본 문장 배열 (인덱스 매칭/재청크화에 사용)
    private let sentences: [String]
    
    /// 데이터베이스 통신을 위한 서비스 객체
    private let scriptManagementService: ScriptManagementServiceProtocol
    
    /// 텍스트 정규화 및 단어 수 계산을 위한 분석기 유틸리티
    private let analyzer = SpeechAnalyzer()
    
    // MARK: - 5. Initializer
    
    /// `FeedbackViewModel`을 초기화합니다.
    /// - Parameters:
    ///   - scriptId: 피드백이 속한 스크립트의 ID
    ///   - diffs: `SpeechAnalyzer`가 반환한 *전체* `WordDiff` 배열 (평탄화된 상태)
    ///   - sentences: `SpeechAnalyzer`에 전달됐던 *원본* 문장 배열
    ///   - practiceDuration: 총 연습 시간
    ///   - scriptManagementService: DB 저장을 위한 서비스 객체
    init(
        scriptId: Int64,
        diffs: [WordDiff],
        sentences: [String],
        practiceDuration: Double,
        scriptManagementService: ScriptManagementServiceProtocol
    ) {
        self.scriptId = scriptId
        self.sentences = sentences
        self.practiceDuration = practiceDuration
        self.scriptManagementService = scriptManagementService
        
        // --- (핵심 로직) 재-청크화(Re-chunking) ---
        // `SpeechAnalyzer`는 문장 구분을 무시하고 하나의 긴 [WordDiff] 배열을 반환합니다.
        // 이 배열을 `sentences` 원본 배열을 기준으로 다시 문장별로 '잘라' `sentenceDiffs`를 생성합니다.
        
        var tempDiffs = diffs // 소비할 전체 diffs 배열
        var chunkedResult: [(original: String, diffs: [WordDiff])] = []
        
        // 원본 문장 배열 순서대로 순회
        for sentence in sentences {
            // 1. 원본 문장을 *동일한 방식*으로 정규화하여 원본 단어 개수를 셈
            let wordCount = analyzer.normalize(sentence).count
            var chunk: [WordDiff] = []
            var wordsTaken = 0 // 현재 문장에서 가져온 단어 수
            
            // 2. `wordCount`에 도달할 때까지 `tempDiffs`에서 diff를 꺼내 `chunk`에 추가
            while wordsTaken < wordCount && !tempDiffs.isEmpty {
                let diff = tempDiffs.removeFirst()
                chunk.append(diff)
                
                // .extra(추가된 단어)는 원본 단어 수(wordsTaken)에 포함되지 않음
                switch diff {
                case .matched, .missing, .replaced:
                    wordsTaken += 1
                case .extra:
                    break
                }
            }
            
            // 3. 문장의 끝에 .extra가 더 붙어있는 경우 모두 가져와 chunk에 추가
            while let nextDiff = tempDiffs.first, case .extra = nextDiff {
                chunk.append(tempDiffs.removeFirst())
            }
            
            // 4. 완성된 chunk를 원본 문장과 짝지어 저장
            chunkedResult.append((original: sentence, diffs: chunk))
        }
        
        // 5. (방어 코드) 모든 문장을 순회했는데 `tempDiffs`에 남은 것이 있다면, 마지막 문장에 붙임
        if !tempDiffs.isEmpty {
            if chunkedResult.isEmpty {
                chunkedResult.append((original: "", diffs: tempDiffs))
            } else {
                chunkedResult[chunkedResult.count - 1].diffs.append(contentsOf: tempDiffs)
            }
        }
        self.sentenceDiffs = chunkedResult
        // --- 재-청크화 완료 ---

        // 오류 개수 카운트는 전체 diffs 배열을 기준으로 계산
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
    
    
    // MARK: - 6. Core Logic (DB Save)
    
    /// 분석 결과를 `FeedbackSummary` 및 `FeedbackDetail`로 변환하여 DB에 저장합니다.
    /// - Parameter practiceDuration: `init`에서 받은 총 연습 시간
    func saveFeedbackResult(practiceDuration: Double) async {
        isSaving = true
        saveError = nil
        
        // --- 1. 데이터 변환 (DB 저장 포맷으로 가공) ---
        // `sentenceDiffs` (문장별)를 `detailsData` (DB 저장용) 형태로 변환
        var detailsData: [(
            wordDiff: WordDiff,
            originalText: String?, // FeedbackDetail의 originalText 필드용
            sentenceIndex: Int,
            wordIndex: Int
        )] = []
        
        // `sentenceDiffs`를 순회하며 *모든* WordDiff를 detailsData에 추가
        for (sIdx, sentenceData) in sentenceDiffs.enumerated() {
            for (wIdx, diff) in sentenceData.diffs.enumerated() {
                
                // DB의 `originalText` 필드에 저장할 원본 단어를 결정
                // (.extra는 원본이 없으므로 nil)
                let originalWord: String?
                switch diff {
                case .matched(let word):
                    originalWord = word
                case .missing(let expected):
                    originalWord = expected
                case .replaced(let expected, _):
                    originalWord = expected
                case .extra:
                    originalWord = nil
                }
                
                // 모든 diff 케이스를 DB에 저장하기 위해 배열에 추가
                detailsData.append((
                    wordDiff: diff,
                    originalText: originalWord,
                    sentenceIndex: sIdx, // 문장 인덱스
                    wordIndex: wIdx      // 문장 내 단어 인덱스
                ))
            }
        }
        
        // --- 2. 서비스 호출 (DB 작업) ---
        do {
            // Task.detached를 사용해 DB 작업을 백그라운드 스레드로 보냄
            // (await 이후 @MainActor로 자동 복귀)
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
            }.value // 백그라운드 작업이 끝나고 결과를 받음

            // 성공
            print("피드백 저장 성공. Summary ID: \(summary.id ?? -1)")
            isSaving = false
            
        } catch {
            // 실패
            print("피드백 저장 실패: \(error)")
            saveError = error
            isSaving = false
        }
    }
}
