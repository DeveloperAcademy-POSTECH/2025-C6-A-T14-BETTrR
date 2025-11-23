//
//  ScoreTrendDataPoint.swift
//  Bettr
//
//  Created by 길정수 on 11/23/25.
//

import SwiftUI

struct ScoreTrendDataPoint: Identifiable {
    let id: Int
    let session: Int
    let score: Int
    
    init(session: Int, score: Int) {
        self.id = session
        self.session = session
        self.score = score
    }
}
