
import Foundation
import GRDB

struct PracticeSession: Identifiable, Codable, FetchableRecord, MutablePersistableRecord {
    var id: Int64?
    var scriptId: Int64
    var recordingPath: String
    var totalPresentationTime: Double
    var createdAt: Date

    static var databaseTableName: String = "practice_session"

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
