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
                GeometryReader { geometry in
                    VStack(alignment: .leading, spacing: 30) {
                        
                        ScriptDashboardTopContents(viewModel: viewModel)
                            .frame(height: geometry.size.height * 0.4)
                        
                        ScriptDashboardBottomContents(viewModel: viewModel)
                            .frame(height: geometry.size.height * 0.6)
                    }
                }
                .padding(.horizontal, 60)
                .padding(.bottom, 60)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .navigationBarTitleDisplayMode(.inline)
            } else {
                // 로딩, 에러 뷰
                LoadingView(
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
