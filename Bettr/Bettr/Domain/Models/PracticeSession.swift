
import Foundation
import GRDB

struct PracticeSession: Identifiable, Codable, FetchableRecord, MutablePersistableRecord {
    var id: Int64?
    var scriptId: Int64
    var recordingPath: String
    var totalPresentationTime: Double
    var createdAt: Date

    static let script = belongsTo(Script.self)
    static let feedbackSummary = hasOne(FeedbackSummary.self)

    static var databaseTableName: String = "practice_session"

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
