import OSLog

/// Centralized, privacy-preserving app diagnostics.
///
/// The `StaticString` input prevents runtime values such as tokens, prompts,
/// AI responses, user content, paths, and arbitrary errors from being logged.
enum AppLog {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.duracell.Bettr"

    static let database = Category("database")
    static let ai = Category("ai")
    static let audio = Category("audio")
    static let document = Category("document")
    static let ui = Category("ui")

    struct Category {
        private let logger: Logger

        fileprivate init(_ name: String) {
            logger = Logger(subsystem: AppLog.subsystem, category: name)
        }

        func debug(_ message: StaticString) {
            #if DEBUG
            logger.debug("\(message.description, privacy: .public)")
            #endif
        }

        func error(_ message: StaticString) {
            logger.error("\(message.description, privacy: .public)")
        }

        func fault(_ message: StaticString) {
            logger.fault("\(message.description, privacy: .public)")
        }
    }
}
