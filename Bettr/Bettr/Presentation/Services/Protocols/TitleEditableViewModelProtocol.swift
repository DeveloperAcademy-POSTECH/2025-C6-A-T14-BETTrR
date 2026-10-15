//
//  TitleEditableViewModelProtocol.swift
//  Bettr
//
//  Created by 길정수 on 11/8/25.
//

import Foundation

protocol TitleEditableViewModelProtocol {
    
    var scriptId: Int64 { get }
    var scriptService: ScriptManagementServiceProtocol { get }
    var currentTitle: String { get set }
    
    func updateLocalModelTitle(_ newTitle: String)
}

extension TitleEditableViewModelProtocol {
    
    /// currentTitle의 didSet에서 호출될 공통 로직
    func handleTitleChange(oldValue: String, newValue: String) {
        if oldValue != "Loading..." && oldValue != newValue {
            // 3. 개별 구현이 필요한 '로컬 모델 업데이트' 호출
            updateLocalModelTitle(newValue)
            
            // 5. 공통 구현인 'DB 저장' 호출
            saveTitleToDatabase(newTitle: newValue)
        }
    }
    
    /// DB에 저장하는 공통 함수 (private으로 숨김)
    private func saveTitleToDatabase(newTitle: String) {
        Task(priority: .background) {
            do {
                try await scriptService.updateScriptTitle(scriptId: scriptId, newTitle: newTitle)
                AppLog.database.debug("스크립트 제목 저장 완료")
            } catch {
                AppLog.database.error("스크립트 제목 저장 실패")
            }
        }
    }
}
