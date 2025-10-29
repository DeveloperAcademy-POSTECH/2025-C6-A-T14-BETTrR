
import Foundation

enum ScriptRepositoryError: Error, LocalizedError, Equatable {
    case validationError(message: String)
    case databaseError(message: String)

    var errorDescription: String? {
        switch self {
        case .validationError(let message):
            return "Validation Error: \(message)"
        case .databaseError(let message):
            return "Database Error: \(message)"
        }
    }
}
