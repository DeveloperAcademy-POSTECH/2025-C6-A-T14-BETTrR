

import Foundation
import GRDB

struct Word: Identifiable, Codable, FetchableRecord, MutablePersistableRecord {
    var id: Int64?
    var scriptId: Int64
    var lemma: String
    var pos: String
    var meaning: String
    var orderIndex: Int
    
    static let script = belongsTo(Script.self)
    
    static var databaseTableName: String = "word"
    
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

// MARK: - Relationships
extension Script {
    static let words = hasMany(Word.self)
}
