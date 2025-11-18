//
//  ToasterView.swift
//  Bettr
//
//  Created by 길정수 on 11/17/25.
//

import SwiftUI

struct ToasterView: View {
    let message: String
    
    var body: some View {
        Text(message)
            .font(.labelRegular14)
            .foregroundStyle(.defaultWhite50)
            .padding(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
            .background(.normalBlack900.opacity(0.75))
            .cornerRadius(20)
            .shadow(radius: 5)
    }
}
