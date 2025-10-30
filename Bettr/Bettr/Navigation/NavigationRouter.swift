//
//  NavigationRouter.swift
//  Bettr
//
//  Created by 길정수 on 10/30/25.
//

import SwiftUI
import Observation

@Observable
class NavigationRouter {
    /// 네비게이션 경로를 저장하는 변수
    var path = NavigationPath()
    
    /// 특정 화면을 추가 (Push 기능)
    /// T라는 이름의 'Hashable' 프로토콜을 따르는
    /// 어떤 타입이든 받을 수 있도록 제네릭 처리
    func push<T: Hashable>(_ route: T) {
        path.append(route)
    }
    
    /// 마지막 화면 제거 (Pop 기능)
    func pop() {
        if !path.isEmpty {
            path.removeLast()
        }
    }
    
    /// 네비게이션 초기화 (전체 Pop)
    func reset() {
        path = NavigationPath()
    }
}
