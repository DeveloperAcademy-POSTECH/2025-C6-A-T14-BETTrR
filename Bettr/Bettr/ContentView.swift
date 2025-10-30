//
//  ContentView.swift
//  Bettr
//
//  Created by 서세린 on 10/30/25.
//

import SwiftUI

import FirebaseAI

//struct ContentView: View {
//    @State private var outputText = "아직 요청 전이에요 ✨"
//    @State private var isLoading = false
//
//    var body: some View {
//        VStack(spacing: 24) {
//            Text("Firebase AI 테스트")
//                .font(.title)
//                .bold()
//
//            ScrollView {
//                Text(outputText)
//                    .padding()
//                    .frame(maxWidth: .infinity, alignment: .leading)
//            }
//            .frame(height: 300)
//            .background(Color(.secondarySystemBackground))
//            .cornerRadius(12)
//
//            if isLoading {
//                ProgressView("AI가 글을 만드는 중...")
//            }
//
//            Button(action: {
//                Task {
//                    await callGemini()
//                }
//            }) {
//                Text("AI 호출하기")
//                    .bold()
//                    .padding()
//                    .frame(maxWidth: .infinity)
//                    .background(Color.blue)
//                    .foregroundColor(.white)
//                    .cornerRadius(12)
//            }
//            .disabled(isLoading)
//        }
//        .padding()
//    }
//
//    // MARK: - Firebase Gemini 호출
//    func callGemini() async {
//        isLoading = true
//        defer { isLoading = false }
//
//        do {
//            // 🔹 Gemini 모델 초기화
//            let ai = FirebaseAI.firebaseAI(backend: .googleAI())
//            let model = ai.generativeModel(modelName: "gemini-2.5-flash")
//
//            // 🔹 프롬프트
//            let prompt = "Write a story about a magic backpack."
//
//            // 🔹 비동기 호출 (await)
//            let response = try await model.generateContent(prompt)
//
//            // 🔹 응답 표시
//            outputText = response.text ?? "(응답 텍스트 없음)"
//            print("✅ Firebase Gemini 응답:", response.text ?? "없음")
//
//        } catch {
//            outputText = "❌ 오류 발생: \(error.localizedDescription)"
//            print("🔥 FirebaseAI 오류:", error.localizedDescription)
//        }
//    }
//}

struct ContentView: View {
    @State private var router = NavigationRouter()
    
    var body: some View {
        NavigationStack(path: $router.path) {
            VStack {
                Button("암기뷰로 이동") {
                    router.push(Route.memorization(title: "스크립트.pdf"))
                }
            }
            .navigationTitle("Home")
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .memorization(let title):
                    MemorizationView(title: title)
                case .recording(let sentences):
                    RecordingView(sentences: sentences)
                }
            }
            .environment(router)
        }
    }
}

#Preview {
    ContentView()
}
