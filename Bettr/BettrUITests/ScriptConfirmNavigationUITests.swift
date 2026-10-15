import XCTest

@MainActor
final class ScriptConfirmNavigationUITests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func test_backButtonShowsExitConfirmationWithoutSystemBackButton() {
        let app = XCUIApplication()
        app.launchEnvironment["XCTestConfigurationFilePath"] = "/tmp/bettr-script-confirm-ui-tests"
        app.launchArguments.append("--script-confirm-ui-test")
        app.launch()
        defer { app.terminate() }
        XCTAssertTrue(app.buttons["스크립트 등록"].waitForExistence(timeout: 10))

        let openFixtureButton = app.buttons["ui-test.open-script-confirm"]
        XCTAssertTrue(openFixtureButton.waitForExistence(timeout: 10))
        openFixtureButton.tap()

        let navigationBar = app.navigationBars.firstMatch
        let guardedBackButton = navigationBar.buttons["script-confirm.back"]
        XCTAssertTrue(guardedBackButton.waitForExistence(timeout: 10))
        XCTAssertEqual(navigationBar.buttons.count, 1)
        XCTAssertFalse(app.buttons["BackButton"].exists)

        guardedBackButton.tap()

        let exitAlert = app.alerts["저장하지 않고 나가시겠어요?"]
        XCTAssertTrue(exitAlert.waitForExistence(timeout: 5))
        exitAlert.buttons["취소"].tap()
        XCTAssertTrue(guardedBackButton.waitForExistence(timeout: 5))
        XCTAssertEqual(navigationBar.buttons.count, 1)
        XCTAssertFalse(app.buttons["BackButton"].exists)

        app.staticTexts["Hello world."].tap()
        XCTAssertTrue(app.textViews["script-confirm.editor"].waitForExistence(timeout: 3))
        XCTAssertEqual(navigationBar.buttons.count, 1)

        guardedBackButton.tap()
        XCTAssertTrue(exitAlert.waitForExistence(timeout: 5))
        exitAlert.buttons["나가기"].tap()

        XCTAssertTrue(openFixtureButton.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["script-confirm.back"].exists)
    }
}
