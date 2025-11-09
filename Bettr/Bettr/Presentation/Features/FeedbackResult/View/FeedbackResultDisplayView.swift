//
//  FeedbackResultDisplayView.swift
//  Bettr
//
//  Created by 길정수 on 11/4/25.
//

import Foundation
import SwiftUI

struct FeedbackResultDisplayView: View {
    let accuracy: Double
    let totalRecordingTime: TimeInterval
    let missingCount: Int
    let extraCount: Int
    let replacedCount: Int
    
    /// (index: 원본 인덱스, data: (original: 원본 문장, diffs: [WordDiff]))
    let filteredSentenceDiffs: [(index: Int, data: (original: String, diffs: [WordDiff]))]
    
    // '완벽합니다' 메시지를 표시할지 여부를 결정
    let hasSentences: Bool
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("📊 피드백 결과")
                    .font(.largeTitle).bold()
                    .padding(.bottom, 10)
                
                Text("전체 정확도: \(Int(accuracy * 100))%")
                    .font(.title)
                    .foregroundColor(.blue)
                    .bold()
                
                Text("총 녹음 시간: \(totalRecordingTime.toMMSSms())")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 5)
                
                HStack(spacing: 12) {
                    Text("오류 분석:")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("누락: \(missingCount)개")
                        .font(.callout.bold())
                        .foregroundColor(.green)
                    
                    Text("추가: \(extraCount)개")
                        .font(.callout.bold())
                        .foregroundColor(.red)
                    
                    Text("대체: \(replacedCount)개")
                        .font(.callout.bold())
                        .foregroundColor(.blue)
                    
                    Spacer()
                }
                .padding(.bottom, 5)
                
                Divider()
                
                if !hasSentences {
                    Text("분석 결과가 없습니다.")
                        .foregroundColor(.gray)
                    
                } else if filteredSentenceDiffs.isEmpty {
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
                    ForEach(filteredSentenceDiffs, id: \.index) { (originalIndex, sentenceData) in
                        
                        // (1) 원본 문장
                        VStack(alignment: .leading, spacing: 8) {
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
                            Text("내 발음 \(originalIndex + 1)")
                                .font(.headline)
                                .foregroundColor(.gray)
                            
                            HighlightedTextView(diffs: sentenceData.diffs)
                                .font(.title3)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .multilineTextAlignment(.leading)
                                .lineSpacing(6)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray5))
                        .cornerRadius(10)
                        
                        if originalIndex != filteredSentenceDiffs.last?.index {
                            Divider()
                                .padding(.vertical, 10)
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    /// WordDiff 배열을 하이라이트된 SwiftUI Text로 변환하는 헬퍼 함수
    /// (ViewModel에서 이곳으로 이동)
    private func buildHighlightText(from diffs: [WordDiff]) -> Text {
        if diffs.isEmpty {
            return Text("(발화 내용 없음)")
                .foregroundStyle(.gray)
        } else {
            var components: [Text] = []
            
            for diff in diffs {
                switch diff {
                case .matched(let word):
                    components.append(Text(word)
                        .foregroundColor(.primary))
                    
                case .missing(let expected):
                    components.append(Text(expected)
                        .foregroundColor(.green)
                        .strikethrough(true, color: .green))
                    
                case .extra(let actual):
                    components.append(Text(actual)
                        .foregroundColor(.red))
                    
                case .replaced(let expected, let actual):
                    components.append(Text(expected)
                        .foregroundColor(.gray)
                        .strikethrough(true, color: .gray))
                    components.append(Text(actual)
                        .foregroundColor(.blue))
                }
            }
            
            guard let first = components.first else {
                return Text("")
            }
            
            return components.dropFirst().reduce(first) { result, component in
                Text("\(result) \(component)")
            }
        }
    }
}

#Preview("일반 피드백") {
    FeedbackResultDisplayView(
        accuracy: 0.75,
        totalRecordingTime: 120.5,
        missingCount: 2,
        extraCount: 1,
        replacedCount: 1,
        filteredSentenceDiffs: [
            (index: 0, data: (original: "Hello world, how are you?", diffs: [
                .matched(word: "Hello"),
                .matched(word: "world"),
                .missing(expected: "how"),
                .extra(actual: "are"),
                .replaced(expected: "you", actual: "yoo")
            ])),
            (index: 1, data: (original: "I am fine, thank you.", diffs: [
                .matched(word: "I"),
                .matched(word: "am"),
                .matched(word: "fine"),
                .extra(actual: "very"),
                .matched(word: "thank"),
                .missing(expected: "you")
            ]))
        ],
        hasSentences: true
    )
}

#Preview("완벽한 발음") {
    FeedbackResultDisplayView(
        accuracy: 1.0,
        totalRecordingTime: 60.0,
        missingCount: 0,
        extraCount: 0,
        replacedCount: 0,
        filteredSentenceDiffs: [],
        hasSentences: true
    )
}

#Preview("분석 결과 없음") {
    FeedbackResultDisplayView(
        accuracy: 0.0,
        totalRecordingTime: 0.0,
        missingCount: 0,
        extraCount: 0,
        replacedCount: 0,
        filteredSentenceDiffs: [],
        hasSentences: false
    )
}


