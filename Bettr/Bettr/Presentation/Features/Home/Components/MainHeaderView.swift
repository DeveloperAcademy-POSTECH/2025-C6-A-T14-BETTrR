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
                    .padding(.leading, 4)
                    
                Spacer()
            }
            
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(.primaryBlue200)
        }
    }
}

#Preview {
    MainHeaderView()
}
