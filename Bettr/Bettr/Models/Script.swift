
import Foundation
import GRDB

struct Script: Identifiable, Codable, FetchableRecord, MutablePersistableRecord {
    var id: Int64?
    var title: String
    var originalEnglishText: String
    var originalKoreanText: String
    var createdAt: Date
    var lastPracticedAt: Date

    static let sentences = hasMany(Sentence.self)
    static let practiceSessions = hasMany(PracticeSession.self)

    static var databaseTableName: String = "script"

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
