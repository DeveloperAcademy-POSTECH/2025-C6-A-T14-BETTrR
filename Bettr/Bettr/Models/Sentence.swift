
import Foundation
import GRDB

struct Sentence: Identifiable, Codable, FetchableRecord, MutablePersistableRecord {
    var id: Int64?
    var scriptId: Int64
    var orderIndex: Int
    var englishText: String
    var koreanText: String

    static let script = belongsTo(Script.self)
    static let chunks = hasMany(Chunk.self)

    static var databaseTableName: String = "sentence"

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
