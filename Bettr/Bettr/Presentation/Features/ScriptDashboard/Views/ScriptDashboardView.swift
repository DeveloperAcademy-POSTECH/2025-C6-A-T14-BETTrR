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

    let columns: [GridItem] = [
        GridItem(.adaptive(minimum: 382), spacing: 32)
    ]
    
    var body: some View {
        Group {
            if viewModel.isLoading { // 로딩
                ProgressView()
            } else if let error = viewModel.currentError { // 에러
                ErrorView(error: error) {
                    Task { // 다시 시도
                        viewModel.retryLoadData()
                    }
                }
            } else if let data = viewModel.scriptDashboardData { // 성공
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 36) {
                        ScriptDashboardTopLeftContents(recentFeedbacks: data.recentFeedbacks)
                        ScriptDashboardTopRightContents(stats: data.stats)
                        ScriptDashboardBottomLeftContents(viewModel: viewModel)
                        ScriptDashboardBottomRightContents(viewModel: viewModel)
                    }
                    .safeAreaPadding(.horizontal, 84)
                }
            } else { // 예외 케이스: 로딩도 아니고, 에러도 아닌데, 데이터도 없는 경우
                ErrorView(error: .unknown("데이터를 불러오지 못했습니다.")) {
                    Task {
                        viewModel.retryLoadData()
                    }
                }
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
