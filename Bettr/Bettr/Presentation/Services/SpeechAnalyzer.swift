//
//  SpeechAnalyzer.swift
//  Bettr
//
//  Created by 길정수 on 10/30/25.
//

import Foundation
import Speech

// MARK: - 분석기 (Levenshtein 기반)
class SpeechAnalyzer {
    
    private let contractionDict: [String: String] = [
        "i'm": "i am", "i've": "i have", "i'll": "i will", "i'd": "i would",
        "you're": "you are", "you've": "you have", "you'll": "you will", "you'd": "you would",
        "he's": "he is", "he'll": "he will", "he'd": "he would",
        "she's": "she is", "she'll": "she will", "she'd": "she would",
        "it's": "it is", "it'll": "it will", "it'd": "it would",
        "we're": "we are", "we've": "we have", "we'll": "we will", "we'd": "we would",
        "they're": "they are", "they've": "they have", "they'll": "they will", "they'd": "they would",
        "isn't": "is not", "aren't": "are not", "wasn't": "was not", "weren't": "were not",
        "hasn't": "has not", "haven't": "have not", "hadn't": "had not",
        "won't": "will not", "wouldn't": "would not",
        "don't": "do not", "doesn't": "does not", "didn't": "did not",
        "can't": "cannot", "couldn't": "could not", "shouldn't": "should not", "mustn't": "must not"
    ]
    
    // 다른 파일에서 접근 가능해야 하므로 Private 키워드 없음
    func normalize(_ text: String) -> [String] {
        var normalized = text.lowercased()
        // 수축형 먼저 풀기
        for (short, full) in contractionDict {
            let pattern = "\\b" + NSRegularExpression.escapedPattern(for: short) + "\\b"
            normalized = normalized.replacingOccurrences(of: pattern, with: full, options: [.regularExpression, .caseInsensitive])
        }
        // 문장부호 제거
        normalized = normalized.replacingOccurrences(of: "[.,!?\"']", with: "", options: .regularExpression)
        // 공백 정리
        normalized = normalized.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        return normalized.split(separator: " ").map(String.init)
    }
    
    func analyze(reference: String, transcription: SFTranscription) -> FeedbackResultModel {
        let referenceWords = normalize(reference)
        let recognizedWords = normalize(transcription.formattedString)
        let n = referenceWords.count
        let m = recognizedWords.count
        
        // Levenshtein DP 테이블
        var dp = Array(repeating: Array(repeating: 0, count: m + 1), count: n + 1)
        for i in 0...n { dp[i][0] = i }
        for j in 0...m { dp[0][j] = j }
        
        for i in 1...n {
            for j in 1...m {
                if referenceWords[i - 1] == recognizedWords[j - 1] {
                    dp[i][j] = dp[i - 1][j - 1]
                } else {
                    dp[i][j] = min(
                        dp[i - 1][j] + 1,      // 삭제 (누락)
                        dp[i][j - 1] + 1,      // 삽입 (추가)
                        dp[i - 1][j - 1] + 1   // 치환 (대체)
                    )
                }
            }
        }
        
        // 추적(백트래킹)
        var i = n
        var j = m
        var diffs: [WordDiff] = []
        
        while i > 0 || j > 0 {
            if i > 0 && j > 0 && referenceWords[i - 1] == recognizedWords[j - 1] {
                // 일치
                diffs.insert(.matched(word: referenceWords[i - 1]), at: 0)
                i -= 1
                j -= 1
            }
            else if i > 0 && j > 0 && dp[i][j] == dp[i - 1][j - 1] + 1 {
                // 대체
                diffs.insert(.replaced(expected: referenceWords[i - 1], actual: recognizedWords[j - 1]), at: 0)
                i -= 1
                j -= 1
            }
            else if i > 0 && dp[i][j] == dp[i - 1][j] + 1 {
                // 누락 (원본O, 발화X)
                diffs.insert(.missing(expected: referenceWords[i - 1]), at: 0)
                i -= 1
            }
            else if j > 0 && dp[i][j] == dp[i][j - 1] + 1 {
                // 추가 (원본X, 발화O)
                diffs.insert(.extra(actual: recognizedWords[j - 1]), at: 0)
                j -= 1
            } else {
                // i=0, j=0 이거나 오류
                break
            }
        }
        
        // 정확도 계산 (matched 기준)
        let matchedCount = diffs.filter {
            if case .matched = $0 { return true }
            return false
        }.count
        
        let accuracy = referenceWords.isEmpty ? 0 : Double(matchedCount) / Double(referenceWords.count)
        
        // FeedbackResultModel 반환
        return FeedbackResultModel(
            diffs: diffs,
            accuracy: accuracy,
            totalOriginalWords: referenceWords.count
        )
    }
}
