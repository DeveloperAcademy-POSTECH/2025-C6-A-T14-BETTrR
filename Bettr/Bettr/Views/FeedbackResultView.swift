//
//  FeedbackResultView.swift
//  Bettr
//
//  Created by 길정수 on 10/30/25.
//

import Foundation
import SwiftUI

// MARK: - 피드백 결과 뷰
struct FeedbackResultView: View {
    let feedback: FeedbackResultModel
    let sentences: [String]
    
    /// 문장별로 청크(chunk)된 Diff 배열
    private let sentenceDiffs: [(original: String, diffs: [WordDiff])]
    
    /// 누락된 단어(Missing) 개수
    private var missingCount: Int {
        feedback.diffs.filter {
            if case .missing = $0 { return true }
            return false
        }.count
    }
    
    /// 추가된 단어(Extra) 개수
    private var extraCount: Int {
        feedback.diffs.filter {
            if case .extra = $0 { return true }
            return false
        }.count
    }
    
    /// 대체된 단어(Replaced) 개수
    private var replacedCount: Int {
        feedback.diffs.filter {
            if case .replaced = $0 { return true }
            return false
        }.count
    }
    
    /// 정규화 및 단어 수 계산을 위한 분석기 인스턴스
    private let analyzer = SpeechAnalyzer()
    
    init(feedback: FeedbackResultModel, sentences: [String]) {
        self.feedback = feedback
        self.sentences = sentences
        
        // --- Diff 배열을 문장별로 청크로 나누는 로직 ---
        
        var tempDiffs = feedback.diffs
        var chunkedResult: [(original: String, diffs: [WordDiff])] = []
        
        for sentence in sentences {
            // 1. 원본 문장의 '정규화된' 단어 수 계산
            //    (이 수만큼 .matched, .missing, .replaced 를 가져와야 함)
            let wordCount = analyzer.normalize(sentence).count
            
            var chunk: [WordDiff] = []
            var wordsTaken = 0 // 현재 청크에 할당된 '원본' 단어 수
            
            // 2. '원본 단어 수' 만큼 Diff를 tempDiffs에서 가져옴
            while wordsTaken < wordCount && !tempDiffs.isEmpty {
                let diff = tempDiffs.removeFirst()
                chunk.append(diff)
                
                // .extra는 원본 단어 수에 포함되지 않으므로 세지 않음
                switch diff {
                case .matched, .missing, .replaced:
                    wordsTaken += 1 // 원본 단어 수 카운트
                case .extra:
                    break // .extra는 카운트하지 않음
                }
            }
            
            // 3. .extra 단어는 원본 단어 사이에 끼어있을 수 있음
            //    다음 '원본' 단어가 나오기 전까지의 .extra 단어는 현재 청크 소속임
            while let nextDiff = tempDiffs.first,
                  case .extra = nextDiff {
                chunk.append(tempDiffs.removeFirst())
            }
            
            chunkedResult.append((original: sentence, diffs: chunk))
        }
        
        // 4. 모든 문장을 처리한 후에도 남은 Diff가 있다면 (보통 마지막 .extra)
        //    마지막 청크에 모두 추가
        if !tempDiffs.isEmpty {
            if chunkedResult.isEmpty {
                // 원본 문장이 아예 없는 경우 (방어 코드)
                chunkedResult.append((original: "", diffs: tempDiffs))
            } else {
                chunkedResult[chunkedResult.count - 1].diffs.append(contentsOf: tempDiffs)
            }
        }
        
        self.sentenceDiffs = chunkedResult
        // --- 청크 로직 끝 ---
    }
    
    /// 원본 인덱스를 유지하면서 틀린 문장만 필터링합니다.
    private var filteredSentenceDiffs: [(index: Int, data: (original: String, diffs: [WordDiff]))] {
        sentenceDiffs.enumerated().filter { (index, data) in
            // data.diffs (diffs 배열)에 .matched 외의 것이 하나라도 있는지 확인
            data.diffs.contains { diff in
                switch diff {
                case .matched:
                    return false // 에러가 아님 (계속 탐색)
                case .missing, .extra, .replaced:
                    return true // ❗️ 에러 발견! (이 문장을 포함)
                }
            }
        }
        .map { (offset, element) in
            // (offset, element) 튜플을 (index, data) 튜플로 변환
            return (index: offset, data: element)
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("📊 피드백 결과")
                    .font(.largeTitle).bold()
                    .padding(.bottom, 10)
                
                Text("전체 정확도: \(Int(feedback.accuracy * 100))%")
                    .font(.title)
                    .foregroundColor(.blue)
                    .bold()
                
                Text("총 녹음 시간: \(feedback.totalRecordingTime.toMMSSms())")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 5)
                
                HStack(spacing: 12) {
                    Text("오류 분석:")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("누락: \(missingCount)개")
                        .font(.callout.bold())
                        .foregroundColor(.green) // 누락 (Green)
                    
                    Text("추가: \(extraCount)개")
                        .font(.callout.bold())
                        .foregroundColor(.red) // 추가 (Red)
                    
                    Text("대체: \(replacedCount)개")
                        .font(.callout.bold())
                        .foregroundColor(.blue) // 대체 (Blue)
                    
                    Spacer()
                }
                .padding(.bottom, 5)
                
                Divider()
                
                // 결과 표시 로직
                if sentenceDiffs.isEmpty {
                    // (A) 분석 결과가 아예 없는 경우
                    Text("분석 결과가 없습니다.")
                        .foregroundColor(.gray)
                } else if filteredSentenceDiffs.isEmpty {
                    // (B) 분석은 했지만, 틀린 문장이 없는 경우 (모두 정답)
                    VStack(alignment: .center, spacing: 10) {
                        Text("🎉 완벽합니다!")
                            .font(.title.bold())
                            .foregroundColor(.green)
                        Text("틀린 문장이 하나도 없습니다.")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                } else {
                    // (C) 틀린 문장이 있는 경우
                    // filteredSentenceDiffs'를 사용하고, id를 \.index로 변경
                    ForEach(filteredSentenceDiffs, id: \.index) { (originalIndex, sentenceData) in
                        
                        // (1) 원본 문장
                        VStack(alignment: .leading, spacing: 8) {
                            // ⭐️ 4. [수정] 'index' 대신 'originalIndex' 사용
                            Text("영어 원문 \(originalIndex + 1)")
                                .font(.headline)
                                .foregroundColor(.gray)
                            Text(sentenceData.original)
                                .font(.title3)
                                .bold()
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        
                        // (2) 사용자 발화 (하이라이트)
                        VStack(alignment: .leading, spacing: 8) {
                            // 'index' 대신 'originalIndex' 사용
                            Text("내 발음 \(originalIndex + 1)")
                                .font(.headline)
                                .foregroundColor(.gray)
                            
                            // WordDiff를 Text로 변환하는 뷰
                            buildHighlightText(from: sentenceData.diffs)
                                .font(.title3)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .multilineTextAlignment(.leading)
                                .lineSpacing(6)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray5)) // 원본과 색 구분
                        .cornerRadius(10)
                        
                        // Divider 표시 로직 변경
                        if originalIndex != filteredSentenceDiffs.last?.index {
                            Divider()
                                .padding(.vertical, 10)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("분석 결과")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    /// WordDiff 배열을 하이라이트된 SwiftUI Text로 변환하는 헬퍼 함수
    ///
    /// - 요구사항 매핑:
    /// - 추가(extra) = 빨강 (Red)
    /// - 누락(missing) = 초록 (Green)
    /// - 대체(replaced) = 파랑 (Blue)
    func buildHighlightText(from diffs: [WordDiff]) -> Text {
        // diffs가 비어있으면 (예: 원본은 있으나 발화가 아예 없음)
        if diffs.isEmpty {
            return Text("(발화 내용 없음)")
                .foregroundStyle(.gray)
        } else {
            // Text를 공백으로 연결
            var components: [Text] = []
            
            for diff in diffs {
                switch diff {
                case .matched(let word):
                    components.append(Text(word)
                        .foregroundColor(.primary)) // 일치 (기본색)
                    
                case .missing(let expected):
                    // 누락 (Green): 발화하지 않았으므로, 취소선으로 표시
                    components.append(Text(expected)
                        .foregroundColor(.green)
                        .strikethrough(true, color: .green))
                    
                case .extra(let actual):
                    // 추가 (Red):
                    components.append(Text(actual)
                        .foregroundColor(.red))
                    
                case .replaced(let expected, let actual):
                    // 대체 (Blue):
                    // (원본: 회색 취소선)
                    components.append(Text(expected)
                        .foregroundColor(.gray)
                        .strikethrough(true, color: .gray))
                    // (발음: 파란색)
                    components.append(Text(actual)
                        .foregroundColor(.blue))
                }
            }
            
            // components를 " " (공백)으로 합침
            var result = Text("")
            if let first = components.first {
                result = first
                for component in components.dropFirst() {
                    result = result + Text(" ") + component
                }
            }
            return result
        }
    }
}
