//
//  HistoricalFeedbackViewModel.swift
//  Bettr
//
//  Created by 길정수 on 11/5/25.
//

import Foundation
import SwiftUI

/// 과거의 피드백(`FeedbackSummary`)을 선택했을 때,
/// 상세 내역(`FeedbackDetail`)과 원본 스크립트(`Script`/`Sentence`)를 DB에서 불러와
/// 피드백 결과 화면을 재구성하는 뷰모델입니다.
@Observable
@MainActor
class HistoricalFeedbackViewModel {
    
    // MARK: - 1. UI State Properties
    
    /// 상세 데이터(Script, FeedbackDetail)를 로드 중인지 여부
    var isLoading = true
    
    /// 데이터 로드 실패 시 발생하는 에러
    var loadError: Error?
    
    // MARK: - 2. Display Properties (View Data)
    
    var resultModel: FeedbackResultModel?
    
    // MARK: - 3. Dependencies & Private Properties
    
    /// 뷰에서 선택한 원본 피드백 요약 객체
    private let summary: FeedbackSummary
    
    /// 데이터베이스 통신을 위한 서비스 객체
    private let scriptManagementService: ScriptManagementServiceProtocol
    
    // init에서 전달받은 메타데이터를 저장할 비공개 프로퍼티 추가
    private let scriptTitle: String
    private let feedbackNumber: Int
    
    // MARK: - 4. Initializer
    
    /// `HistoricalFeedbackViewModel`을 초기화합니다.
    /// - Parameters:
    ///   - summary: 사용자가 목록에서 선택한 `FeedbackSummary` 객체
    ///   - scriptTitle: 스크립트 제목 (이전 뷰에서 전달)
    ///   - feedbackNumber: 이 피드백의 순번 (이전 뷰에서 전달, 예: 5)
    ///   - scriptManagementService: DB 조회를 위한 서비스 객체
    init(
        summary: FeedbackSummary,
        scriptTitle: String,
        feedbackNumber: Int,
        scriptManagementService: ScriptManagementServiceProtocol
    ) {
        self.summary = summary
        self.scriptManagementService = scriptManagementService
        
        // 1. 메타데이터를 비공개 프로퍼티에 저장해 둡니다.
        //    (로딩 완료 후 resultModel을 만들 때 사용)
        self.scriptTitle = scriptTitle
        self.feedbackNumber = feedbackNumber
        
        // 2. 상세 내역(resultModel)은 비동기로 로드
    }
    
    // MARK: - 5. Core Logic (Data Loading & Reconstruction)
    
    /// 뷰가 나타날 때(`.task`) 호출되어, 상세 피드백 데이터를 비동기로 로드하고 재구성합니다.
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
            // --- 1. DB에서 원본 스크립트와 피드백 상세 내역을 병렬로 로드 ---
            async let scriptTask = scriptManagementService.fetchScriptWithSentences(id: summary.scriptId)
            async let detailsTask = scriptManagementService.fetchFeedbackDetails(forFeedbackSummaryId: summaryId)
            
            // 두 작업이 모두 완료될 때까지 대기
            let originalScriptData = try await scriptTask
            let feedbackDetails = try await detailsTask // (DB에 저장된 '모든' diff 목록)
            
            // --- 2. 원본 문장 데이터 준비 ---
            let originalSentences = originalScriptData?.sentences ?? []
            // (원본 문장 텍스트를 `sentenceIndex`로 빠르게 찾기 위한 맵)
            var sentenceTextMap: [Int: String] = [:]
            for (sIdx, sentence) in originalSentences.enumerated() {
                // DB의 `orderIndex`가 0부터 시작한다는 가정 (만약 다르다면 sentence.orderIndex를 키로 사용)
                sentenceTextMap[sIdx] = sentence.englishText
            }
            
            // --- 3. [핵심 로직] FeedbackDetail을 문장별 WordDiff로 재조립 ---
            // `FeedbackViewModel`의 `sentenceDiffs`와 동일한 형태를 복원합니다.
            
            // 3a. Details를 `sentenceIndex` -> `wordIndex` 순으로 정렬
            let sortedDetails = feedbackDetails.sorted {
                if $0.sentenceIndex != $1.sentenceIndex {
                    return $0.sentenceIndex < $1.sentenceIndex // 문장 인덱스 우선
                }
                return $0.wordIndex < $1.wordIndex // 그 다음 단어 인덱스
            }
            
            // 3b. 정렬된 Details를 `sentenceIndex`를 키로 하여 그룹화
            let detailsBySentence = Dictionary(grouping: sortedDetails, by: { $0.sentenceIndex })
            
            // 재구성된 결과를 담을 배열
            var reconstructedSentenceDiffs: [(original: String, diffs: [WordDiff])] = []
            
            // 3c. *원본 문장 순서*대로 순회하며 데이터 재조립
            // (originalSentences.count 또는 sentenceTextMap의 최대 인덱스 기준)
            for sIdx in 0..<originalSentences.count {
                let originalText = sentenceTextMap[sIdx] ?? "" // 원본 문장 텍스트
                
                if let detailsForSentence = detailsBySentence[sIdx] {
                    // 이 문장에 해당하는 `FeedbackDetail` 목록 (이미 wordIndex 순으로 정렬됨)
                    
                    // 3d. [FeedbackDetail] -> [WordDiff]로 변환
                    //      (FeedbackDetail 모델의 `wordDiff` computed property 활용)
                    let diffs = detailsForSentence.map { $0.wordDiff }
                    reconstructedSentenceDiffs.append((original: originalText, diffs: diffs))
                    
                } else {
                    // (방어 코드) 이 문장에 해당하는 피드백 상세 내역이 없는 경우
                    reconstructedSentenceDiffs.append((original: originalText, diffs: []))
                }
            }
            
            // --- 4. 가공된 데이터를 UI가 사용할 형태로 필터링 ---
            
            // '.matched' 외의 오류가 있는 문장만 필터링
            let finalFilteredDiffs = reconstructedSentenceDiffs.enumerated()
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
            
            // --- 5. [핵심] 모든 데이터를 조합하여 `resultModel` 생성 ---
            // 9개의 개별 프로퍼티에 값을 할당하는 대신,
            // init에서 받은 summary와 메타데이터, 방금 로드한 diffs를 사용해
            // FeedbackResultModel 인스턴스 하나를 생성합니다.
            self.resultModel = FeedbackResultModel(
                scriptTitle: self.scriptTitle,             // init에서 저장
                feedbackNumber: self.feedbackNumber,       // init에서 저장
                accuracy: self.summary.accuracy,           // init에서 저장 (summary)
                totalRecordingTime: self.summary.practiceDuration, // init에서 저장 (summary)
                missingCount: self.summary.missingWordCount,
                extraCount: self.summary.addedWordCount,
                replacedCount: self.summary.replacedWordCount,
                filteredSentenceDiffs: finalFilteredDiffs  // 방금 로드/가공
            )
            
            self.isLoading = false // 로딩 완료
            
        } catch {
            // --- 5. 에러 처리 ---
            print("피드백 상세 정보 불러오기 실패: \(error)")
            self.loadError = error
            self.isLoading = false
        }
    }
}
