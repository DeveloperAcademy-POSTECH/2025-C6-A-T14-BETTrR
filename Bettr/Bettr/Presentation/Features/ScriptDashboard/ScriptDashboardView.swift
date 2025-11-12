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
        GeometryReader { geo in
            let metrics = LayoutMetrics(width: geo.size.width)
            
            dashboardContent(metrics: metrics)
                .environment(\.metrics, metrics)
        }
        .onTapGesture {
            isTitleEditing = false
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                EditableTitleView(
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
    
    @ViewBuilder
    private func dashboardContent(metrics: LayoutMetrics) -> some View {
        Group {
            if viewModel.scriptDashboardData != nil {
                
                Grid(horizontalSpacing: metrics.gridHorizontalSpacing,
                     verticalSpacing: metrics.gridVerticalSpacing) {
                    GridRow {
                        ScriptDashboardTopLeftContents(feedbacks: viewModel.scriptDashboardData!.recentFeedbacks)
                        
                        ScriptDashboardTopRightContents(
                            feedbackCount: viewModel.scriptDashboardData!.feedbackCount,
                            top3IncorrectWords: viewModel.scriptDashboardData!.top3IncorrectWords,
                            averagePracticeDuration: viewModel.scriptDashboardData!.averagePracticeDuration,
                            recentFeedbackCount: viewModel.scriptDashboardData!.recentFeedbackCount
                        )
                    }
                    
                    GridRow {
                        ScriptDashboardBottomLeftContents(
                            recentFeedbacks: viewModel.scriptDashboardData!.recentFeedbacks,
                            allFeedbacks: viewModel.scriptDashboardData!.allFeedbacks,
                            scriptTitle: viewModel.currentTitle,
                            feedbackNumber: viewModel.scriptDashboardData!.feedbackCount
                        )
                        
                        ScriptDashboardBottomRightContents(
                            scriptId: viewModel.scriptId,
                            sentences: viewModel.scriptDashboardData!.sentences,
                            scriptTitle: viewModel.currentTitle,
                            currentFeedbackNumber: viewModel.scriptDashboardData!.feedbackCount
                        )
                    }
                }
            } else {
                LoadingView(
                    isLoading: viewModel.isLoading,
                    errorMessage: viewModel.errorMessage
                )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, metrics.horizontalPadding)
        .padding(.top, metrics.topPadding)
        .padding(.bottom, metrics.bottomPadding)
    }
}

