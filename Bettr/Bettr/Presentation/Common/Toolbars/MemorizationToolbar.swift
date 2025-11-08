//
//  MemorizationToolbar.swift
//  Bettr
//
//  Created by 길정수 on 10/29/25.
//

import SwiftUI

struct MemorizationToolbar: ViewModifier {
    
    @Binding var title: String
    let showEditIcon: Bool
    @Binding var isTitleEditing: Bool
    
    @Binding var isChunkMode: Bool
    @Binding var functionMode: FunctionMode
    @Binding var languageMode: LanguageMode
    @Binding var isWordListOpen: Bool
    @Binding var isPlaying: Bool
    @Binding var isPause: Bool
    @Binding var isFeedbackModalOpen: Bool
    let isRecordingDisabled: Bool
    
    func body(content: Content) -> some View {
        content
            .toolbar {
                // 타이틀
                ToolbarItem(placement: .principal) {
                    EditableTitleView(title: $title, showEditIcon: showEditIcon, isEditing: $isTitleEditing )
                }
                
                // 상단 오른쪽 툴 바
                ToolbarItem {
                    Button(action: {
                        isChunkMode.toggle()
                    }) {
                        Image(systemName: isChunkMode ? "text.word.spacing" : "text.justify")
                    }
                }
                
                ToolbarSpacer(.flexible)
                
                ToolbarItemGroup {
                    Button(action: {
                        functionMode = .hide
                    }) {
                        Image(systemName: "bandage")
                            .foregroundStyle(functionMode == .hide ? .primary : .quinary)
                    }
                    Button(action: {
                        functionMode = .read
                    }) {
                        Image(systemName: "speaker.wave.2")
                            .foregroundStyle(functionMode == .read ? .primary : .quinary)
                    }
                }
                
                ToolbarSpacer(.flexible)
                
                ToolbarItemGroup {
                    Button(action: {
                        languageMode = .engKor
                    }) {
                        Image(systemName: "translate")
                            .foregroundStyle(languageMode == .engKor ? .primary : .quinary)
                    }
                    Button(action: {
                        languageMode = .engOnly
                    }) {
                        Image(systemName: "character")
                            .foregroundStyle(languageMode == .engOnly ? .primary : .quinary)
                    }
                }
                
                ToolbarSpacer(.flexible)
                
                ToolbarItem {
                    Button(action: {
                        isWordListOpen.toggle()
                    }) {
                        Image(systemName: "character.book.closed")
                            .foregroundStyle(isWordListOpen ? .blue : .primary)
                    }
                }
                
                // 하단 툴 바
                ToolbarItemGroup(placement: .bottomBar) {
                    // 왼쪽 버튼
                    if isPlaying {
                        ControlGroup {
                            Button(action: {
                                isPause.toggle()
                            }) {
                                Image(systemName: isPause ? "play.fill" : "pause.fill")
                            }
                            
                            Button(action: {
                                isPlaying = false
                                isPause = false
                            }) {
                                Image(systemName: "stop.fill")
                            }
                        }
                    } else {
                        Button(action: {
                            isPlaying = true
                        }) {
                            Image(systemName: "play.fill")
                        }
                    }
                    
                    Spacer()
                    
                    // 오른쪽 버튼
                    Button(action: {
                        isFeedbackModalOpen.toggle()
                    }) {
                        Image(systemName: "append.page")
                            .foregroundStyle(Color.blue)
                    }
                    .disabled(isRecordingDisabled)
                }
            }
    }
}

extension View {
    func memorizationToolbar(
        title: Binding<String>,
        showEditIcon: Bool = false,
        isTitleEditing: Binding<Bool>,
        isChunkMode: Binding<Bool>,
        functionMode: Binding<FunctionMode>,
        languageMode: Binding<LanguageMode>,
        isWordListOpen: Binding<Bool>,
        isPlaying: Binding<Bool>,
        isPause: Binding<Bool>,
        isFeedbackModalOpen: Binding<Bool>,
        isRecordingDisabled: Bool
    ) -> some View {
        self.modifier(MemorizationToolbar(
            title: title,
            showEditIcon: showEditIcon,
            isTitleEditing: isTitleEditing,
            isChunkMode: isChunkMode,
            functionMode: functionMode,
            languageMode: languageMode,
            isWordListOpen: isWordListOpen,
            isPlaying: isPlaying,
            isPause: isPause,
            isFeedbackModalOpen: isFeedbackModalOpen,
            isRecordingDisabled: isRecordingDisabled
        ))
    }
}
