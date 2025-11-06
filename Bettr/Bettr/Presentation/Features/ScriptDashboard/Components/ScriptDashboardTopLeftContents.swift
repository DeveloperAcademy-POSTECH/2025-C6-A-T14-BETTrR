//
//  ScriptDashboardTopLeftContents.swift
//  Bettr
//
//  Created by 길정수 on 11/6/25.
//

import SwiftUI

struct ScriptDashboardTopLeftContents: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("그래프")
                .padding(.vertical, 25)
                .padding(.horizontal, 40)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.primary.opacity(0.05))
                )
        }
    }
}
