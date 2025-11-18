//
//  MemorizationToolbar.swift
//  Bettr
//
//  Created by 길정수 on 10/29/25.
//

import SwiftUI

enum FunctionMode {
    case hide   // 가리기
    case read   // 재생
}

struct MemorizationToolbarContent: ToolbarContent {
    
    @Bindable var viewModel: MemorizationViewModel
    let showEditIcon: Bool
    
    var body: some ToolbarContent {
        // 타이틀
        ToolbarItem(placement: .principal) {
            EditableTitle(
                title: $viewModel.currentTitle,
                showEditIcon: showEditIcon,
                isEditing: $viewModel.uiState.isTitleEditing
            )
        }
        
        topToolbarItems
        
        bottomToolbarItems
    }
    
    
    @ToolbarContentBuilder
    private var topToolbarItems: some ToolbarContent {
        // 청크 모드
        ToolbarItem {
            Button(action: {
                viewModel.toggleChunkMode()
            }) {
                Image(systemName: "text.word.spacing")
                    .toolbarButtonStyle(emphasized: viewModel.uiState.isChunkMode)
            }
        }
        
        ToolbarSpacer(.flexible)
        
        // 기능 모드 (Hide/Read)
        ToolbarItemGroup {
            Button(action: {
                viewModel.setFunctionMode(.hide)
            }) {
                Image(systemName: "bandage")
                    .toolbarButtonStyle(enabled: viewModel.uiState.funcMode == .hide)
            }
            Button(action: {
                viewModel.setFunctionMode(.read)
            }) {
                Image(systemName: "speaker.wave.2")
                    .toolbarButtonStyle(enabled: viewModel.uiState.funcMode == .read)
            }
        }
        
        ToolbarSpacer(.flexible)
        
        // 한국어 토글
        ToolbarItem {
            Button(action: {
                viewModel.uiState.isKoreanVisible.toggle()
            }) {
                Text("한")
                    .toolbarButtonStyle(emphasized: viewModel.uiState.isKoreanVisible)
            }
        }
        
        ToolbarSpacer(.flexible)
        
        // 단어장
        ToolbarItem {
            Button(action: {
                viewModel.uiState.showWordList.toggle()
            }) {
                Image(systemName: "character.book.closed")
                    .toolbarButtonStyle(emphasized: viewModel.uiState.showWordList)
            }
        }
    }
    
    @ToolbarContentBuilder
    private var bottomToolbarItems: some ToolbarContent {
        ToolbarItemGroup(placement: .bottomBar) {
            // 왼쪽 버튼 (재생/일시정지/정지)
            playbackControls
            
            Spacer()
            
            // 오른쪽 버튼 (피드백)
            feedbackButton
        }
    }
    
    @ViewBuilder
    private var playbackControls: some View {
        if viewModel.uiState.isPlaying {
            ControlGroup {
                Button(action: {
                    viewModel.togglePauseResume()
                }) {
                    Image(systemName: viewModel.uiState.isPause ? "play.fill" : "pause.fill")
                }
                
                Button(action: {
                    viewModel.togglePlayStop()
                }) {
                    Image(systemName: "stop.fill")
                }
            }
        } else {
            Button(action: {
                viewModel.togglePlayStop()
            }) {
                Image(systemName: "play.fill")
            }
        }
    }
    
    private var feedbackButton: some View {
        Button(action: {
            viewModel.uiState.showFeedbackModal.toggle()
        }) {
            Image(systemName: "append.page")
                .toolbarButtonStyle(enabled: !viewModel.isRecordingDisabled)
        }
        .disabled(viewModel.isRecordingDisabled)
    }
}
