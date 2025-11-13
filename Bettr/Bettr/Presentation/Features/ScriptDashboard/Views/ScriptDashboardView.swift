//
//  ScriptDashboardView.swift
//  Bettr
//
//  Created by 길정수 on 11/4/25.
//

import SwiftUI

struct ScriptDashboardView: View {
    @State var viewModel: ScriptDashboardViewModel
    @State private var isTitleEditing: Bool = false
    
    init(viewModel: ScriptDashboardViewModel) {
        _viewModel = State(initialValue: viewModel)
    }
    
    var body: some View {
        Group {
            if let data = viewModel.scriptDashboardData {
                ScrollView {
                    VStack(spacing: 36) {
                        HStack(alignment: .top, spacing: 32) {
                            ScriptDashboardTopLeftContents(recentFeedbacks: data.recentFeedbacks)
                            ScriptDashboardTopRightContents(stats: data.stats)
                        }
                        .frame(maxHeight: 272)
                        
                        HStack(alignment: .top, spacing: 32) {
                            ScriptDashboardBottomLeftContents(viewModel: viewModel)
                            ScriptDashboardBottomRightContents(viewModel: viewModel)
                        }
                        .frame(maxHeight: 607)
                    }
                    .safeAreaPadding(.horizontal, 84)
                }
            } else {
                LoadingView(
                    isLoading: viewModel.isLoading,
                    errorMessage: viewModel.errorMessage
                )
            }
        }
        .safeAreaPadding(.top, 24)
        .safeAreaPadding(.bottom, 48)
        .onTapGesture {
            isTitleEditing = false
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                EditableTitle(
                    title: $viewModel.currentTitle,
                    showEditIcon: true,
                    isEditing: $isTitleEditing
                )
            }
        }
        .onAppear {
            viewModel.onAppear()
        }
    }
}
