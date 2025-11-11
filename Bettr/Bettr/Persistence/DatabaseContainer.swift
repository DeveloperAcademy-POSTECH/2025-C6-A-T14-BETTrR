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
    let wordExtractionService: WordExtractionService
    var scripts: [Script] = []
    
    init(database: AppDatabase) {
        self.scriptRepository = ScriptRepository(dbQueue: database.dbQueue)
        self.scriptManagementService = ScriptManagementService(scriptRepository: self.scriptRepository)
        self.wordExtractionService = WordExtractionService(
            dbQueue: database.dbQueue,
            scriptRepository: scriptRepository,
            scriptManagementService: scriptManagementService
        )
    }
    
    func refreshScripts() {
        do {
            self.scripts = try self.scriptManagementService.fetchAllScripts().sorted { $0.lastViewedAt > $1.lastViewedAt }
        } catch {
            print("Failed to fetch scripts: \(error)")
        }
    }
    
    static func getForPreview(withMockData: Bool = true) -> DatabaseContainer {
        do {
            let db = try AppDatabase.makeInMemory()
            let container = DatabaseContainer(database: db)
            if withMockData {
                try DemoDataGenerator.generate(into: db)
            }
            container.refreshScripts()
            return container
        } catch {
            fatalError("Failed to create container for preview: \(error)")
        }
    }
}
