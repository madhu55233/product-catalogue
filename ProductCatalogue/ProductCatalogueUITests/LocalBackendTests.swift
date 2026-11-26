import XCTest

final class LocalBackendTests: XCTestCase {
    @MainActor
    func testLocalBackendLoadsCatalogueSearchAndDetails() throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["RUN_LOCAL_BACKEND_TESTS"] == "1",
                          "Opt in with TEST_RUNNER_RUN_LOCAL_BACKEND_TESTS=1 and start the backend on port 3000.")
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--use-local-backend"]
        app.launch()

        let category = app.buttons["category-link-electronics"]
        XCTAssertTrue(category.waitForExistence(timeout: 65), app.debugDescription)
        category.tap()
        XCTAssertTrue(app.navigationBars["electronics"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "product-tile-")).firstMatch.waitForExistence(timeout: 65))
        let edge = app.coordinate(withNormalizedOffset: CGVector(dx: 0.01, dy: 0.5))
        let destination = app.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.5))
        edge.press(forDuration: 0.1, thenDragTo: destination)
        XCTAssertTrue(app.navigationBars["Catalogue"].waitForExistence(timeout: 10))

        let search = app.textFields["product-search-input"]
        XCTAssertTrue(search.waitForExistence(timeout: 10))
        search.tap()
        search.typeText("Fjallraven")
        app.buttons["product-search-button"].tap()
        let product = app.buttons["product-tile-1"]
        XCTAssertTrue(product.waitForExistence(timeout: 65))
        product.tap()
        let title = app.staticTexts["product-details-title"]
        XCTAssertTrue(title.waitForExistence(timeout: 65))
        XCTAssertTrue(title.label.contains("Fjallraven"))
        XCTAssertTrue(app.buttons["product-enquire-button"].exists)
    }
}
