//
//  ScriptDashboardView.swift
//  Bettr
//
//  Created by 길정수 on 11/4/25.
//

import SwiftUI

struct ScriptDashboardView: View {
    var viewModel: ScriptDashboardViewModel
    
    var body: some View {
        Group {
            if viewModel.scriptDashboardData != nil {
                GeometryReader { geo in
                    VStack(alignment: .leading, spacing: 30) {
                        ScriptDashboardTopContents(viewModel: viewModel)
                            .frame(height: geo.size.height * 0.4)
                        ScriptDashboardBottomContents(viewModel: viewModel)
                            .frame(height: geo.size.height * 0.6)
                    }
                }
                .padding(.horizontal, 60)
                .padding(.bottom, 60)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .navigationBarTitleDisplayMode(.inline)
            } else {
                // 로딩, 에러 뷰
                DashboardLoadingView(
                    isLoading: !viewModel.showingError,
                    errorMessage: viewModel.errorMessage
                )
                
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(viewModel.scriptDashboardData?.title ?? "")
        .onAppear {
            viewModel.onAppear()
        }
    }
}

struct ScriptDashboardTopContents: View {
    @Environment(NavigationRouter.self) var router
    var viewModel: ScriptDashboardViewModel
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 20) {
                ForEach(viewModel.scriptDashboardData?.sentences ?? [], id: \.orderIndex) { sentence in
                    Text(sentence.englishText)
                        .font(.system(size: 20))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(maxHeight: .infinity, alignment: .top)
            
            Button(action: {
                router.push(Route.memorization(scriptId: viewModel.scriptId))
            }) {
                Text("암기하기")
                    .foregroundStyle(.white)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 50)
                    .background(
                        RoundedRectangle(cornerRadius: 100)
                            .fill(Color.blue)
                    )
                    .glassEffect()
            }
        }
        .padding(.vertical, 25)
        .padding(.horizontal, 40)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.primary.opacity(0.05))
                .strokeBorder(Color.primary.opacity(0.5), lineWidth: 1)
        )
        .clipped()
    }
}

struct ScriptDashboardBottomContents: View {
    var viewModel: ScriptDashboardViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 25)
        .padding(.horizontal, 50)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.primary.opacity(0.05))
                .strokeBorder(Color.primary.opacity(0.5), lineWidth: 1)
        )
    }
}
