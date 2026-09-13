
import Foundation
import GRDB

struct Script: Identifiable, Codable, FetchableRecord, MutablePersistableRecord {
    var id: Int64?
    var title: String
    var createdAt: Date
    var lastViewedAt: Date

    static let sentences = hasMany(Sentence.self)
    static let feedbackSummaries = hasMany(FeedbackSummary.self)

    static var databaseTableName: String = "script"

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

// MARK: - Creation and State Changes
extension Script {
    static func from(_ data: ScriptData, createdAt: Date) -> Script {
        Script(
            id: nil,
            title: data.title,
            createdAt: createdAt,
            lastViewedAt: createdAt
        )
    }

    mutating func markViewed(at date: Date) {
        lastViewedAt = date
    }
}

// MARK: - Relationships
extension Script {
    // Script의 모든 Sentence 가져오기
    var sentencesRequest: QueryInterfaceRequest<Sentence> {
        request(for: Script.sentences)
    }
    
    // Script의 모든 FeedbackSummary 가져오기
    var feedbackSummariesRequest: QueryInterfaceRequest<FeedbackSummary> {
        request(for: Script.feedbackSummaries)
    }
}
