//
//  DatabaseContainer.swift
//  Bettr
//
//  Created by oliver on 10/30/25.
//

import Foundation
import Combine

@Observable
class DatabaseContainer {
    let scriptRepository: ScriptRepository
    let scriptManagementService: ScriptManagementService
    let practiceSessionService: PracticeSessionService
    let wordExtractionService: WordExtractionService
    
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
        self.wordExtractionService = WordExtractionService(
            dbQueue: database.dbQueue,
            scriptRepository: scriptRepository,
            scriptManagementService: scriptManagementService
        )
    }
}
