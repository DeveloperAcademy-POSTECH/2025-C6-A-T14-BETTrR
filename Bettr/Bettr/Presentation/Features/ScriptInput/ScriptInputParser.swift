//
//  ScriptInputParser.swift
//  Bettr
//
//  Created by 서세린 on 11/5/25.
//

import Foundation

// MARK: - Gemini가 생성한 json 처리로직
// JSON 응답을 Swift 구조체로 매핑하는 함수
// 기존의 'parseGeminiOutputToScriptData' 대신 새롭게 추가됨
func parseGeminiJSONToScriptData(_ jsonText: String, fallbackTitle: String) -> ScriptData? {
    // 코드펜스 제거 (Gemini가 ```json 으로 감싸는 경우 대비)
    let trimmed = jsonText
//        .replacingOccurrences(of: "```json", with: "")
//        .replacingOccurrences(of: "```", with: "")
        .replacingOccurrences(of: "```json", with: "")
        .replacingOccurrences(of: "```", with: "")
        .trimmingCharacters(in: .whitespacesAndNewlines)
    
    guard let data = trimmed.data(using: .utf8) else { return nil }
    
    do {
        // Gemini가 orderIndex를 주므로, 별도 enumerated() 보정 불필요
        let decoded = try JSONDecoder().decode(ScriptData.self, from: data)

        // title이 비어 있을 경우 대비
        let finalTitle = decoded.title.isEmpty ? fallbackTitle : decoded.title

        // 그대로 반환 (orderIndex는 Gemini가 부여한 값 사용)
        return ScriptData(title: finalTitle, sentences: decoded.sentences)
        
    } catch {
        print("⚠️ JSON 디코딩 실패: \(error)")
        return nil
    }
}
