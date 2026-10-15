import Foundation
import FirebaseAILogic

func classifyGeminiCallError(_ error: Error) -> AIError {
    if let aiError = error as? AIError {
        return aiError
    }

    if error is CancellationError {
        return .cancelled
    }

    if let urlError = error as? URLError {
        switch urlError.code {
        case .cancelled:
            return .cancelled
        case .cannotParseResponse, .badServerResponse:
            return .responseContract
        case .timedOut, .cannotConnectToHost, .networkConnectionLost, .notConnectedToInternet:
            return .transient
        default:
            return .unknown
        }
    }

    if error is DecodingError {
        return .responseContract
    }

    switch error {
    case GenerateContentError.promptBlocked, GenerateContentError.responseStoppedEarly:
        return .responseContract
    case GenerateContentError.promptImageContentError:
        return .invalidInput
    case let GenerateContentError.internalError(underlying):
        return classifyGeminiCallError(underlying)
    default:
        break
    }

    let nsError = error as NSError
    guard nsError.domain == "com.google.firebase.firebaseai.BackendError" else {
        return .unknown
    }

    switch nsError.code {
    case 400, 404, 413, 414, 422:
        return .invalidInput
    case 401, 403:
        return .authentication
    case 408, 500...504:
        return .transient
    case 429:
        return .rateLimited
    case 499:
        return .cancelled
    default:
        return .unknown
    }
}
