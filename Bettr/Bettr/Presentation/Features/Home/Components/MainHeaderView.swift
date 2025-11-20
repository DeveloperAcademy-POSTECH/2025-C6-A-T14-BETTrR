//
//  MainHeaderView.swift
//  Bettr
//
//  Created by oliver on 11/11/25.
//

import SwiftUI

struct MainHeaderView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(.brandLogo)
                    .padding(.leading, 48)
                    
                Spacer()
            }
            
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(.primaryBlue200)
                .padding(.horizontal, 44)
        }
    }
}

#Preview {
    MainHeaderView()
}
