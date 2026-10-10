import Foundation

@MainActor
enum AppLaunchContext {
    static var usesIsolatedDependencies: Bool {
        let environment = ProcessInfo.processInfo.environment
        return NSClassFromString("XCTestCase") != nil
            || environment["XCTestConfigurationFilePath"] != nil
            || environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }

    static func makeComposition() throws -> AppComposition {
        if usesIsolatedDependencies {
            return try PreviewComposition.make()
        }
        return AppComposition.live()
    }
}
