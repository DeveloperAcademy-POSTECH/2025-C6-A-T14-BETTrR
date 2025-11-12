//
//  LoadingView.swift
//  Bettr
//
//  Created by 길정수 on 11/6/25.
//

import SwiftUI

struct LoadingView: View {
    let isLoading: Bool
    let errorMessage: String?
    
    var body: some View {
        if let errorMessage = errorMessage, !errorMessage.isEmpty {
            Text(errorMessage)
                .foregroundColor(.red)
        } else if isLoading {
            ProgressView()
        } else {
            Text("Error! Data Not Found")
        }
    }
}
