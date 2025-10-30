//
//  DatabaseContainer.swift
//  Bettr
//
//  Created by oliver on 10/30/25.
//

import Foundation
import Combine

class DatabaseContainer: ObservableObject {
    let scriptRepository: ScriptRepository
    let scriptManagementService: ScriptManagementService
    let practiceSessionService: PracticeSessionService
    
    init(database: AppDatabase) {
        self.scriptRepository = ScriptRepository()
        self.scriptManagementService = ScriptManagementService(
            dbQueue: database.dbQueue,
            scriptRepository: scriptRepository
        )
        self.practiceSessionService = PracticeSessionService(
            dbQueue: database.dbQueue,
            scriptRepository: scriptRepository
        )
    }
}
