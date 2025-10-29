
import Foundation
import GRDB

struct Sentence: Identifiable, Codable, FetchableRecord, MutablePersistableRecord {
    var id: Int64?
    var scriptId: Int64
    var orderIndex: Int
    var englishText: String
    var koreanText: String

    static var databaseTableName: String = "sentence"

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
