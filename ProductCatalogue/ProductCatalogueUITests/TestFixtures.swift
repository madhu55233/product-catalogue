import XCTest

extension XCUIApplication {
    @MainActor
    func launchWithFixtures() {
        launchArguments += ["--use-test-fixtures"]
        launch()
    }
}