import SwiftUI

@available(iOS 16.0, macOS 13.0, *)
struct CenteredFixedSizeFlowLayout: Layout {
    var itemSize: CGSize
    var horizontalSpacing: CGFloat
    var verticalSpacing: CGFloat
    
    init(
        itemSize: CGSize,
        horizontalSpacing: CGFloat = 36,
        verticalSpacing: CGFloat = 60
    ) {
        self.itemSize = itemSize
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
    }
    
    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        guard let availableWidth = proposal.width, !subviews.isEmpty else { return .zero }
        
        let itemsPerRow = max(1, Int((availableWidth + horizontalSpacing) / (itemSize.width + horizontalSpacing)))
        let rowCount = Int(ceil(Double(subviews.count) / Double(itemsPerRow)))
        let totalHeight = CGFloat(rowCount) * itemSize.height + CGFloat(max(0, rowCount - 1)) * verticalSpacing
        
        return CGSize(width: availableWidth, height: totalHeight)
    }
    
    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        guard !subviews.isEmpty else { return }
        
        let itemsPerRow = max(1, Int((bounds.width + horizontalSpacing) / (itemSize.width + horizontalSpacing)))
        let rows = Array(subviews).chunked(into: itemsPerRow)
        
        // Calculate the width of a full row to determine the grid's centered starting position.
        let fullRowWidth = CGFloat(itemsPerRow) * itemSize.width + CGFloat(max(0, itemsPerRow - 1)) * horizontalSpacing
        let startX = bounds.minX + (bounds.width - fullRowWidth) / 2
        
        var currentY = bounds.minY
        
        for row in rows {
            var currentX = startX
            
            for subview in row {
                subview.place(
                    at: CGPoint(x: currentX, y: currentY),
                    anchor: .topLeading,
                    proposal: ProposedViewSize(itemSize)
                )
                currentX += itemSize.width + horizontalSpacing
            }
            
            currentY += itemSize.height + verticalSpacing
        }
    }
}

// Private helper to keep this self-contained and not modify common extension files.
private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard !self.isEmpty, size > 0 else { return [] }
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
