//
//  WordkListView.swift
//  Bettr
//
//  Created by 길정수 on 10/29/25.
//

import SwiftUI

struct WordkListView: View {
    var body: some View {
        VStack(alignment: .leading) {
            Text("단어장")
                .font(.title)
                .padding(.bottom, 20)
            
            Text("sanctions: 제재")
            Text("targeting: 겨냥한")
            Text("effort: 노력")
            
            Spacer()
        }
        .padding(50)
        .frame(maxWidth: 300, maxHeight: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 35)
                .fill(.regularMaterial)
        )
    }
}

#Preview {
    WordkListView()
}
