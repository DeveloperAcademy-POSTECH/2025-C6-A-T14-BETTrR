//
//  MemorizationToolbar.swift
//  Bettr
//
//  Created by 길정수 on 10/29/25.
//

import SwiftUI

// 툴바 기능 모드
enum FunctionMode {
    case hide   // 가리기
    case read   // 재생
}

// 툴바 언어 모드
enum LanguageMode {
    case engKor   // 한/영
    case engOnly  // 영어만
}

struct MemorizationToolbar: ViewModifier {
    
    let title: String
    @Binding var isChunkMode: Bool
    @Binding var functionMode: FunctionMode
    @Binding var languageMode: LanguageMode
    @Binding var isWordListOpen: Bool
    @Binding var isPlaying: Bool
    @Binding var isFeedbackModalOpen: Bool
    
    func body(content: Content) -> some View {
        content
            .toolbar {
                // 타이틀
                ToolbarItem(placement: .principal) {
                    Text(title)
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
                                isPlaying = false
                            }) {
                                Image(systemName: "pause.fill")
                            }
                            
                            Button(action: {
                                isPlaying = false
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
                }
            }
    }
}

extension View {
    func memorizationToolbar(
        title: String,
        isChunkMode: Binding<Bool>,
        functionMode: Binding<FunctionMode>,
        languageMode: Binding<LanguageMode>,
        isWordListOpen: Binding<Bool>,
        isPlaying: Binding<Bool>,
        isFeedbackModalOpen: Binding<Bool>
    ) -> some View {
        self.modifier(MemorizationToolbar(
            title: title,
            isChunkMode: isChunkMode,
            functionMode: functionMode,
            languageMode: languageMode,
            isWordListOpen: isWordListOpen,
            isPlaying: isPlaying,
            isFeedbackModalOpen: isFeedbackModalOpen
        ))
    }
}
