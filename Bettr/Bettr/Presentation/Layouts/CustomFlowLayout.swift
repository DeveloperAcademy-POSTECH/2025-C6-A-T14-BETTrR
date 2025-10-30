import SwiftUI

// iOS 16, macOS 13 이상에서만 사용 가능
@available(iOS 16.0, macOS 13.0, *)
struct CustomFlowLayout: Layout {
    var spacing: CGFloat // 뷰 사이의 가로, 세로 간격
    
    init(spacing: CGFloat = 8) {
        self.spacing = spacing
    }
    
    // 1. 레이아웃이 차지할 전체 크기를 계산하는 함수 (이 함수는 수정할 필요 없습니다)
    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        guard let availableWidth = proposal.width else { return .zero }
        
        var (currentX, currentLineHeight, totalHeight) = (CGFloat.zero, CGFloat.zero, CGFloat.zero)

        for subview in subviews {
            let subviewSize = subview.sizeThatFits(.unspecified)
            
            if currentX + subviewSize.width > availableWidth {
                totalHeight += currentLineHeight + spacing
                currentX = 0
                currentLineHeight = 0
            }
            
            currentX += subviewSize.width + spacing
            currentLineHeight = max(currentLineHeight, subviewSize.height)
        }
        
        totalHeight += currentLineHeight

        return CGSize(width: availableWidth, height: totalHeight)
    }

    // 2. 계산된 크기 안에 자식 뷰들을 배치하는 함수 (✅ 이 함수를 통째로 교체하세요)
    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        // --- Pass 1: 뷰들을 '줄(Line)' 단위로 그룹화하고 각 줄의 높이를 계산 ---
        
        // 각 '줄'의 정보를 담을 구조체
        struct Line {
            var subviews: [LayoutSubviews.Element] = []
            var height: CGFloat = 0
        }
        
        var lines: [Line] = [Line()] // 첫 번째 빈 줄로 시작
        
        guard !subviews.isEmpty else { return } // 뷰가 없으면 종료
        
        var currentX = bounds.minX
        
        for subview in subviews {
            let subviewSize = subview.sizeThatFits(.unspecified)
            
            // 현재 줄에 공간이 부족하면 (단, 줄의 시작이 아닐 때)
            if currentX != bounds.minX && currentX + subviewSize.width > bounds.maxX {
                // 새 줄을 추가
                lines.append(Line())
                currentX = bounds.minX // X좌표 리셋
            }
            
            // 현재 줄(lines 배열의 마지막 요소)에 뷰를 추가
            lines[lines.count - 1].subviews.append(subview)
            // 현재 줄의 최대 높이를 갱신
            lines[lines.count - 1].height = max(lines.last!.height, subviewSize.height)
            // X좌표 이동
            currentX += subviewSize.width + spacing
        }
        
        // --- Pass 2: 계산된 '줄' 정보를 바탕으로 뷰를 중앙 정렬하여 배치 ---
        
        var currentY = bounds.minY // 첫 번째 줄의 Y좌표
        
        for line in lines {
            var currentX = bounds.minX // 매 줄마다 X좌표 리셋
            
            for subview in line.subviews {
                let subviewSize = subview.sizeThatFits(.unspecified)
                
                // ✅ 중앙 정렬을 위한 Y 오프셋 계산
                // (줄의 최대 높이 - 현재 뷰의 높이) / 2
                let yOffset = (line.height - subviewSize.height) / 2
                
                // 뷰를 계산된 위치에 배치
                subview.place(
                    at: CGPoint(x: currentX, y: currentY + yOffset), // ✅ Y + 오프셋
                    anchor: .topLeading,
                    proposal: .unspecified
                )
                
                // 다음 뷰를 위해 X좌표 이동
                currentX += subviewSize.width + spacing
            }
            
            // 다음 '줄'을 위해 Y좌표 이동
            currentY += line.height + spacing
        }
    }
}
