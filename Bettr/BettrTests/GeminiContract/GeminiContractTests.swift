import FirebaseAppCheck
import FirebaseCore
import XCTest
@testable import Bettr
@testable import BettrAI

@MainActor
final class GeminiContractTests: XCTestCase {
    func test_scriptAnalysis_preservesStructuralContract() async {
        await verify {
            let adapter = try self.makeAdapter()
            // Fixed public fixture, including an OCR heading and unfinished sentence.
            let source = """
            LEARNING ENGLISH
            Despite the challenging weather, the team completed the mission.
            When I started learning
            """
            let script = try await GeminiContractDeadline.run {
                try await adapter.analyzeScript(source)
            }
            // Reuse the production validator (including coverage normalization).
            guard let json = String(data: try JSONEncoder().encode(script), encoding: .utf8) else {
                throw GeminiContractFailure.responseContract
            }
            _ = try GeminiScriptParser.parse(json, sourceText: source, fallbackTitle: "Contract fixture")
        }
    }

    func test_wordExtraction_preservesStructuralContract() async {
        await verify {
            let adapter = try self.makeAdapter()
            let words = try await GeminiContractDeadline.run {
                try await adapter.extractWords(from:
                    "Despite the challenging weather, the researchers demonstrated remarkable resilience."
                )
            }
            guard let json = String(data: try JSONEncoder().encode(words), encoding: .utf8) else {
                throw GeminiContractFailure.responseContract
            }
            _ = try GeminiWordParser.parse(json)
        }
    }

    private func verify(_ operation: () async throws -> Void) async {
        do {
            try await operation()
        } catch {
            XCTFail("GeminiContract failure: \(GeminiContractFailure(error: error).rawValue)")
        }
    }

    private func makeAdapter() throws -> FirebaseGeminiAdapter {
        try GeminiContractConfiguration.validateEnvironment(ProcessInfo.processInfo.environment)
        if FirebaseApp.app() == nil {
            guard let url = Bundle.main.url(forResource: "GoogleService-Info", withExtension: "plist"),
                  let data = try? Data(contentsOf: url), let bundleID = Bundle.main.bundleIdentifier else {
                throw GeminiContractFailure.configuration
            }
            try GeminiContractConfiguration.validatePlist(data, bundleIdentifier: bundleID)
            guard let options = FirebaseOptions(contentsOfFile: url.path) else {
                throw GeminiContractFailure.configuration
            }
            // Must precede provider creation. Never enable Firebase debug logging in this plan.
            FirebaseConfiguration.shared.setLoggerLevel(.error)
            AppCheck.setAppCheckProviderFactory(ContractDebugProviderFactory())
            FirebaseApp.configure(options: options)
        }
        return FirebaseGeminiAdapter()
    }
}

/// The standard DebugProviderFactory logs localDebugToken even when CI supplies a token.
/// Use the same SDK provider without that logging wrapper, after environment preflight.
private final class ContractDebugProviderFactory: NSObject, AppCheckProviderFactory {
    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
        AppCheckDebugProvider(app: app)
    }
}
