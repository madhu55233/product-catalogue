import XCTest

final class CategoryNavigationTests: XCTestCase {
    @MainActor
    func testBrowseCategoriesAndReturnHome() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()

        let electronics = app.buttons["category-link-Electronics"]
        XCTAssertTrue(electronics.waitForExistence(timeout: 5))
        electronics.tap()

        XCTAssertTrue(app.navigationBars["Electronics"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Featured products"].exists)

        for id in [2, 4, 6] {
            let tile = app.descendants(matching: .any)
                .matching(identifier: "product-tile-\(id)").firstMatch
            for _ in 0..<4 {
                if tile.exists && tile.isHittable { break }
                app.swipeUp()
            }
            XCTAssertTrue(tile.exists, "Expected Electronics product \(id)")
            XCTAssertTrue(tile.isHittable)
        }
        XCTAssertTrue(app.staticTexts["More products"].exists)
        XCTAssertFalse(app.descendants(matching: .any)
            .matching(identifier: "product-tile-1").firstMatch.exists)

        // Exercise the native Back gesture without relying on Simulator toolbar metadata.
        let edge = app.coordinate(withNormalizedOffset: CGVector(dx: 0.01, dy: 0.5))
        let destination = app.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.5))
        edge.press(forDuration: 0.1, thenDragTo: destination)
        XCTAssertTrue(app.navigationBars["Catalogue"].waitForExistence(timeout: 5))

        let clothing = app.buttons["category-link-Clothing"]
        XCTAssertTrue(clothing.waitForExistence(timeout: 5))
        clothing.tap()

        XCTAssertTrue(app.navigationBars["Clothing"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any)
            .matching(identifier: "product-tile-3").firstMatch.exists)
        XCTAssertFalse(app.staticTexts["More products"].exists)
    }
}
