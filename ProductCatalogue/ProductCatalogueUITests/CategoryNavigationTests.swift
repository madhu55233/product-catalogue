import XCTest

final class CategoryNavigationTests: XCTestCase {
    @MainActor
    func testHomeSeparatesCategoriesAndFeaturedProducts() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchWithFixtures()

        let electronics = app.buttons["category-link-Electronics"]
        XCTAssertTrue(electronics.waitForExistence(timeout: 5))
        XCTAssertEqual(electronics.label, "Electronics, 3 products")
        XCTAssertEqual(app.buttons["category-link-Clothing"].label, "Clothing, 1 product")
        XCTAssertEqual(app.buttons["category-link-Accessories"].label, "Accessories, 3 products")

        let categories = app.staticTexts["Categories"]
        let featured = app.staticTexts["Featured products"]
        XCTAssertTrue(categories.exists)
        XCTAssertTrue(featured.exists)
        XCTAssertLessThan(categories.frame.minY, featured.frame.minY)

        for id in [1, 2, 3, 4, 5] {
            let tile = app.descendants(matching: .any)
                .matching(identifier: "product-tile-\(id)").firstMatch
            for _ in 0..<6 {
                if tile.exists && tile.isHittable { break }
                app.swipeUp()
            }
            XCTAssertTrue(tile.exists, "Expected featured product \(id)")
            XCTAssertTrue(tile.isHittable)
        }
        for id in [6, 7] {
            XCTAssertFalse(app.descendants(matching: .any)
                .matching(identifier: "product-tile-\(id)").firstMatch.exists)
        }
    }

    @MainActor
    func testCategoryNavigationAtAccessibilityTextSize() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launchWithFixtures()

        XCTAssertTrue(app.buttons["category-link-Accessories"].waitForExistence(timeout: 5))
        let electronics = app.buttons["category-link-Electronics"]
        for _ in 0..<8 {
            if electronics.exists && electronics.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(electronics.isHittable)
        XCTAssertEqual(electronics.label, "Electronics, 3 products")
        electronics.tap()
        XCTAssertTrue(app.navigationBars["Electronics"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testBrowseCategoriesAndReturnHome() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchWithFixtures()

        let electronics = app.buttons["category-link-Electronics"]
        XCTAssertTrue(electronics.waitForExistence(timeout: 5))
        electronics.tap()

        XCTAssertTrue(app.navigationBars["Electronics"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Featured products"].waitForExistence(timeout: 5))

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
            .matching(identifier: "product-tile-3").firstMatch.waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["More products"].exists)
    }
}
