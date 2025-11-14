
import Foundation

enum ScriptRepositoryError: Error, LocalizedError, Equatable {
    case validationError(message: String)
    case databaseError(message: String)
    case notFound(message: String)

    var isNotFoundError: Bool {
        if case .notFound = self { return true }
        return false
    }

    var errorDescription: String? {
        switch self {
        case .validationError(let message):
            return "Validation Error: \(message)"
        case .databaseError(let message):
            return "Database Error: \(message)"
        case .notFound(let message):
            return "Not Found Error: \(message)"
        }
    }
}
