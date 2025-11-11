//
//  LayoutMetrics.swift
//  Bettr
//
//  Created by 길정수 on 11/11/25.
//

import SwiftUI

/// 13인치(가로)를 기준으로 현재 화면 너비에 따라 모든 크기를 비례적으로 계산하는 구조체
struct LayoutMetrics {
    
    // --- 기준 ---
    static let baseWidth: CGFloat = 1366.0 // 13인치 iPad Pro (가로)
    let scaleFactor: CGFloat
    
    // --- 여백 (Padding & Spacing) ---
    // ScriptDashboardView
    let horizontalPadding: CGFloat
    let topPadding: CGFloat
    let bottomPadding: CGFloat
    let gridHorizontalSpacing: CGFloat
    let gridVerticalSpacing: CGFloat
    
    // ScriptDashboardBottomLeftContents
    let listSpacing: CGFloat
    let cardSpacing: CGFloat
    let buttonSpacing: CGFloat
    
    // DashboardCardStyle
    let cardPadding36: CGFloat
    let cardPadding24: CGFloat
    let cardPadding16: CGFloat
    
    // ScriptDashboardTopRightContents
    let topRightStackSpacing: CGFloat
    let top3WordsSpacing: CGFloat

    // --- 폰트 크기 ---
    let font14: CGFloat
    let font16: CGFloat
    let font20: CGFloat
    let font24: CGFloat
    let font32: CGFloat
    
    
    init(width: CGFloat) {
        // 2. 현재 너비 / 기준 너비로 축소/확대 비율 계산
        self.scaleFactor = width / Self.baseWidth
        
        // --- 여백 계산 ---
        self.horizontalPadding = 84.0 * scaleFactor
        self.topPadding = 36.0 * scaleFactor
        self.bottomPadding = 48.0 * scaleFactor
        self.gridHorizontalSpacing = 32.0 * scaleFactor
        self.gridVerticalSpacing = 36.0 * scaleFactor
        
        self.listSpacing = 24.0 * scaleFactor
        self.cardSpacing = 8.0 * scaleFactor
        self.buttonSpacing = 6.0 * scaleFactor
        
        self.cardPadding36 = 36.0 * scaleFactor
        self.cardPadding24 = 24.0 * scaleFactor
        self.cardPadding16 = 16.0 * scaleFactor
        
        self.topRightStackSpacing = 16.0 * scaleFactor
        self.top3WordsSpacing = 24.0 * scaleFactor

        // --- 폰트 크기 계산 ---
        self.font14 = 14.0 * scaleFactor
        self.font16 = 16.0 * scaleFactor
        self.font20 = 20.0 * scaleFactor
        self.font24 = 24.0 * scaleFactor
        self.font32 = 32.0 * scaleFactor
    }
}


private struct LayoutMetricsKey: EnvironmentKey {
    static let defaultValue = LayoutMetrics(width: LayoutMetrics.baseWidth)
}

extension EnvironmentValues {
    var metrics: LayoutMetrics {
        get { self[LayoutMetricsKey.self] }
        set { self[LayoutMetricsKey.self] = newValue }
    }
}
