//
//  ScriptInputView.swift
//  Bettr
//
//  Created by 서세린 on 10/28/25.
//

import SwiftUI
import FirebaseAI

import Foundation

struct ChunkData: Codable, Hashable {
    var orderIndex: Int
    var englishText: String
    var koreanText: String
}

struct SentenceData: Codable, Hashable {
    var orderIndex: Int
    var englishText: String
    var koreanText: String
    var chunks: [ChunkData]
}

struct ScriptData: Codable, Hashable {
    var title: String
    var sentences: [SentenceData]
}

struct ScriptInputView: View {
    @State private var scriptText: String = ""       // 사용자가 입력한 스크립트 저장용 변수
    @State private var isLoading: Bool = false              // FirebaseAI 호출 중 로딩 상태
    @State private var parsedScript: ScriptData?     // Gemini 분석 후 결과 저장(추가)
    
//    //상태 변수들
//    @State private var originalSentences: [String] = []     // 문장 단위 영어 원문
//    @State private var fullTranslations: [String] = []      // 각 문장의 전체 번역
//    @State private var englishChunks: [String] = []         // 각 문장의 청크(영문)
//    @State private var koreanChunks: [String] = []          // 각 문장의 청크(번역)

    var body: some View {
        VStack(spacing: 20) {
            Text("영어 스크립트를 입력하세요")
                .font(.headline)
            
            // 텍스트 입력창
            TextEditor(text: $scriptText)
                .frame(height: 300)
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.5))
                )
                .padding(.horizontal)
            
            // Gemini 호출 버튼
            Button(action: {
                Task {
                    await callGemini()
                }
            }) {
                if isLoading {
                    ProgressView("Gemini가 분석 중...")
                        .tint(.white)
                } else {
                    Text("Gemini에게 분석 요청")
                        .bold()
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .disabled(scriptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
            .padding(.horizontal)
            
//            // 결과 표시 (추후에 없앨 수 있음. 확인용)
//            ScrollView {
//                VStack(alignment: .leading, spacing: 16) {
//                    ForEach(0..<originalSentences.count, id: \.self) { i in
//                        VStack(alignment: .leading, spacing: 8) {
//                            Text("🗣️ Sentence \(i + 1)")
//                                .font(.headline)
//                            GroupBox(label: Text("영어 원문")) {
//                                Text(originalSentences[i])
//                            }
//                            GroupBox(label: Text("영어 청크")) {
//                                Text(englishChunks[safe: i] ?? "")
//                            }
//                            GroupBox(label: Text("한국어 청크")) {
//                                Text(koreanChunks[safe: i] ?? "")
//                            }
//                            GroupBox(label: Text("자연스러운 번역")) {
//                                Text(fullTranslations[safe: i] ?? "")
//                            }
//                        }
//                        .padding(.horizontal)
//                    }
//                }
//            }
            
            // 결과 표시 (파싱 버전 삽입용)
            if let script = parsedScript {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(script.sentences, id: \.orderIndex) { sentence in
                            VStack(alignment: .leading, spacing: 8) {
                                Text("🗣️ Sentence \(sentence.orderIndex + 1)")
                                    .font(.headline)
                                
                                GroupBox(label: Text("영문 문장")) {
                                    Text(sentence.englishText)
                                }
                                GroupBox(label: Text("자연스러운 번역")) {
                                    Text(sentence.koreanText)
                                }
                                
                                GroupBox(label: Text("청크 매칭")) {
                                    ForEach(sentence.chunks, id: \.orderIndex) { chunk in
                                        VStack(alignment: .leading) {
                                            Text("EN: \(chunk.englishText)")
                                            Text("KR: \(chunk.koreanText)")
                                                .foregroundColor(.secondary)
                                        }
                                        .padding(.vertical, 2)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            } else {
                Text("아직 분석 결과가 없습니다.")
                    .foregroundColor(.gray)
            }
        }
        .padding()
    }
    
    // MARK: - 저장 + AI 호출
    func callGemini() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let ai = FirebaseAI.firebaseAI(backend: .googleAI())
            let model = ai.generativeModel(modelName: "gemini-2.5-flash")
            
            //프롬프트 ("/" 기준으로 나누는 형식만 요청)
            let prompt = """
당신은 이제부터 20년 경력의 영어-한국어 언어코치입니다.

# 지시문
아래 가이드라인에 따라 영어 문장을 의미 단위 청크(Chunk)로 나누고, 각 청크에 대응하는 자연스러운 한국어 번역을 제공합니다. 또한 각 문장 전체의 자연스러운 한 문장 번역을 제시하세요.

# Chunking Guideline
1. **의미 중심 분할(Meaning-led)**: 문장의 의미를 우선으로 하며, 애매할 경우 의미상 자연스러운 곳에서 끊습니다. 한 청크는 3~8단어 정도의 한 호흡 길이로 유지합니다.
2. **문법 구조 존중(Grammar-aware)**: 주어(S)+동사(V)는 분리하지 않습니다. (S+V 결속)  
5형식(SVOC)은 S+V / O+OC로 나누되, 목적어(O)와 목적격보어(OC)는 함께 유지합니다. 보어가 절 형태라면 내부에서만 분할 가능합니다.
3. **전치사 결속(Preposition attachment)**: 전치사와 보어를 분리하지 않습니다.  
- 예: “in the midst / of a vast ocean / of material prosperity” (전치사 단절 금지)
- “to/for/of which” 같은 pied-piping 구조는 한 청크로 유지하되 너무 길면 메인 동사 경계에서만 분할합니다.
4. **호흡과 리듬(Breath & Rhythm)**: 의미의 흐름이 자연스러우면서도 한 번에 읽기 좋은 리듬을 유지하세요.
5. **커버리지(Coverage)**: 모든 단어와 구두점을 포함하며 순서를 바꾸거나 생략하지 않습니다. 구두점은 바로 앞 청크에 붙입니다.
6. **출력 규칙(Output format)**:
Sentence 1
Original sentence:
<문장 1의 원문을 그대로 한 줄로 표시>
English (meaning-based chunks):
<문장 1을 의미 단위로 / 구분하여 표시>
Korean (aligned chunks):
<각 청크에 대한 한국어 번역, 동일 개수 유지>
Full natural translation:
<전체 문장을 자연스러운 한국어로 번역>

Sentence 2
Original sentence:
<문장 2의 원문을 그대로 한 줄로 표시>
English (meaning-based chunks):
<문장 2를 의미 단위로 / 구분하여 표시>
Korean (aligned chunks):
<각 청크에 대한 한국어 번역>
Full natural translation:
<자연스러운 전체 번역>

…and so on for all sentences.

# 입력 형식
- 영어 문장 : [청크 분할과 번역이 필요한 영어 스크립트]

# 출력 예시
Sentence 1
Original sentence:
When the architects of our republic wrote the magnificent words of the Constitution and the Declaration of Independence, they were signing a promissory note to which every American was to fall heir.
English (meaning-based chunks):
When the architects of our republic wrote / the magnificent words / of the Constitution / and the Declaration of Independence / they were signing a promissory note / to which every American was to fall heir.
Korean (aligned chunks):
우리 공화국의 설계자들이 썼을 때 / 웅대한 문구를 / 헌법의 / 그리고 독립 선언문의 / 그들은 약속 어음에 서명하고 있었다 / 모든 미국인이 상속받을 어음에.
Full natural translation:
우리 공화국의 설계자들은 헌법과 독립선언서의 웅대한 문구를 쓸 때, 모든 미국인이 상속받게 될 약속 어음에 서명하고 있었다.

이제 다음 영어 스크립트를 처리하세요:
\(scriptText)
"""
            let response = try await model.generateContent(prompt)
            guard let text = response.text else {
                print("⚠️ 응답 없음")
                return
            }

            print("Gemini 응답:\n\(text)")
            
//            // 각 섹션별로 단순 분류 (파싱 아님)
//            let sections = text.components(separatedBy: "Sentence ")
//                .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
//
//            for section in sections {
//                var original = ""
//                var english = ""
//                var korean = ""
//                var full = ""
//
//                // \r 제거 및 라인 배열 생성
//                let cleanedSection = section.replacingOccurrences(of: "\r", with: "")
//                let lines = cleanedSection.split(separator: "\n").map {
//                    String($0).trimmingCharacters(in: .whitespacesAndNewlines)
//                }
//
//                // 줄바꿈 구조 대응
//                for (index, line) in lines.enumerated() {
//                    if line.contains("Original sentence:") {
//                        // ➕ 다음 줄에 실제 문장이 있을 가능성 있음
//                        if index + 1 < lines.count {
//                            original = lines[index + 1]
//                        }
//                    } else if line.contains("English (meaning-based chunks):") {
//                        if index + 1 < lines.count {
//                            english = lines[index + 1]
//                        }
//                    } else if line.contains("Korean (aligned chunks):") {
//                        if index + 1 < lines.count {
//                            korean = lines[index + 1]
//                        }
//                    } else if line.contains("Full natural translation:") {
//                        if index + 1 < lines.count {
//                            full = lines[index + 1]
//                        }
//                    }
//                }
//
//                // UI 업데이트는 MainActor에서 진행
//                await MainActor.run {
//                    if !original.isEmpty { originalSentences.append(original) }
//                    if !english.isEmpty { englishChunks.append(english) }
//                    if !korean.isEmpty { koreanChunks.append(korean) }
//                    if !full.isEmpty { fullTranslations.append(full) }
//                }
//            }
//            // 콘솔에 배열 크기 출력
//            print("배열 크기 — originalSentences: \(originalSentences.count), englishChunks: \(englishChunks.count), koreanChunks: \(koreanChunks.count), fullTranslations: \(fullTranslations.count)")
            
            // ✅ 파싱
            let parsed = parseGeminiOutputToScriptData(text, title: "사용자 입력 스크립트")

            await MainActor.run {
                self.parsedScript = parsed
            }

            print("✅ 총 문장 수: \(parsed.sentences.count)")

        } catch {
            print("🔥 FirebaseAI 오류:", error.localizedDescription)
        }
    }
}

func parseGeminiOutputToScriptData(_ text: String, title: String) -> ScriptData {
    let sections = text.components(separatedBy: "Sentence ")
        .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    
    var sentences: [SentenceData] = []

    for (index, section) in sections.enumerated() {
        var englishText = ""
        var koreanText = ""
        var englishChunks: [String] = []
        var koreanChunks: [String] = []

        let cleanedSection = section.replacingOccurrences(of: "\r", with: "")
        let lines = cleanedSection.split(separator: "\n").map {
            String($0).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        for (i, line) in lines.enumerated() {
            if line.starts(with: "Original sentence:") {
                // 바로 다음 줄이 존재한다면 그걸 사용
                if i + 1 < lines.count {
                    englishText = lines[i + 1].trimmingCharacters(in: .whitespaces)
                }
            } else if line.starts(with: "Full natural translation:") {
                if i + 1 < lines.count {
                    koreanText = lines[i + 1].trimmingCharacters(in: .whitespaces)
                }
            } else if line.starts(with: "English (meaning-based chunks):") {
                if i + 1 < lines.count {
                    let chunkLine = lines[i + 1].trimmingCharacters(in: .whitespaces)
                    englishChunks = chunkLine.components(separatedBy: " / ").map { $0.trimmingCharacters(in: .whitespaces) }
                }
            } else if line.starts(with: "Korean (aligned chunks):") {
                if i + 1 < lines.count {
                    let chunkLine = lines[i + 1].trimmingCharacters(in: .whitespaces)
                    koreanChunks = chunkLine.components(separatedBy: " / ").map { $0.trimmingCharacters(in: .whitespaces) }
                }
            }
        }

        let chunks: [ChunkData] = zip(englishChunks.indices, englishChunks).map { (i, eng) in
            ChunkData(orderIndex: i, englishText: eng, koreanText: koreanChunks[safe: i] ?? "")
        }

        let sentence = SentenceData(orderIndex: index, englishText: englishText, koreanText: koreanText, chunks: chunks)
        sentences.append(sentence)
    }

    return ScriptData(title: title, sentences: sentences)
}

// 🔹 안전한 인덱스 접근용 확장
extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    ScriptInputView()
}
