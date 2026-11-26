import XCTest

final class ProductDetailsTests: XCTestCase {
    @MainActor
    func testHomeTileOpensSelectedProductAndReturnsToCatalogue() {
        continueAfterFailure = false
        let app = launchApp()
        openProduct(1, in: app)

        assertDetails(
            in: app, title: "Everyday Backpack", category: "Accessories", price: "$65.00",
            description: "A lightweight backpack with a padded laptop pocket.", featured: true
        )
        goBack(in: app)
        XCTAssertTrue(app.navigationBars["Catalogue"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["product-tile-1"].exists)
    }

    @MainActor
    func testAdditionalCategoryProductOpensItsOwnDetails() {
        continueAfterFailure = false
        let app = launchApp()
        let category = app.buttons["category-link-Electronics"]
        XCTAssertTrue(category.waitForExistence(timeout: 5))
        category.tap()
        XCTAssertTrue(app.navigationBars["Electronics"].waitForExistence(timeout: 5))
        openProduct(6, in: app)

        assertDetails(
            in: app, title: "Portable Speaker", category: "Electronics", price: "$55.00",
            description: "A compact wireless speaker for music on the go.", featured: false
        )
        goBack(in: app)
        XCTAssertTrue(app.navigationBars["Electronics"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["product-tile-6"].exists)
    }

    @MainActor
    func testSearchProductDetailsPreserveQueryAndAllowAnotherSelection() {
        continueAfterFailure = false
        let app = launchApp()
        let input = app.textFields["product-search-input"]
        XCTAssertTrue(input.waitForExistence(timeout: 5))
        input.tap()
        input.typeText("speaker")
        app.buttons["product-search-button"].tap()
        openProduct(6, in: app)
        assertDetails(
            in: app, title: "Portable Speaker", category: "Electronics", price: "$55.00",
            description: "A compact wireless speaker for music on the go.", featured: false
        )

        goBack(in: app)
        XCTAssertTrue(input.waitForExistence(timeout: 5))
        XCTAssertEqual(input.value as? String, "speaker")
        XCTAssertTrue(app.staticTexts["Search results"].exists)
        XCTAssertTrue(app.buttons["product-tile-6"].exists)
        XCTAssertFalse(app.buttons["product-tile-1"].exists)

        app.buttons["product-search-clear"].tap()
        input.tap()
        input.typeText("lamp")
        app.buttons["product-search-button"].tap()
        openProduct(4, in: app)
        assertDetails(
            in: app, title: "Desk Lamp", category: "Electronics", price: "$45.00",
            description: "An adjustable LED lamp for your workspace.", featured: true
        )
    }

    @MainActor
    func testDetailsRemainScrollableAtAccessibilityTextSize() {
        continueAfterFailure = false
        let app = launchApp(accessibilityTextSize: true)
        let input = app.textFields["product-search-input"]
        XCTAssertTrue(input.waitForExistence(timeout: 5))
        input.tap()
        input.typeText("canvas")
        app.buttons["product-search-button"].tap()
        openProduct(7, in: app)

        assertDetails(
            in: app, title: "Canvas Tote", category: "Accessories", price: "$20.00",
            description: "A reusable canvas bag with reinforced handles.", featured: false
        )
        goBack(in: app)
        XCTAssertTrue(app.textFields["product-search-input"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.textFields["product-search-input"].value as? String, "canvas")
    }

    @MainActor
    private func launchApp(accessibilityTextSize: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        if accessibilityTextSize {
            app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        }
        app.launchWithFixtures()
        XCTAssertTrue(app.textFields["product-search-input"].waitForExistence(timeout: 5))
        return app
    }

    @MainActor
    private func openProduct(_ id: Int, in app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        let tile = app.buttons["product-tile-\(id)"]
        for _ in 0..<10 {
            if tile.exists && tile.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(tile.exists, file: file, line: line)
        XCTAssertTrue(tile.isHittable, file: file, line: line)
        tile.tap()
        XCTAssertTrue(app.navigationBars["Product details"].waitForExistence(timeout: 5), file: file, line: line)
    }

    @MainActor
    private func assertDetails(
        in app: XCUIApplication, title: String, category: String, price: String,
        description: String, featured: Bool, file: StaticString = #filePath, line: UInt = #line
    ) {
        XCTAssertTrue(app.staticTexts["product-details-title"].waitForExistence(timeout: 5), file: file, line: line)
        XCTAssertEqual(app.staticTexts["product-details-title"].label, title, file: file, line: line)
        XCTAssertEqual(app.staticTexts["product-details-category"].label, category, file: file, line: line)
        XCTAssertEqual(app.staticTexts["product-details-price"].label, price, file: file, line: line)
        XCTAssertEqual(app.descendants(matching: .any)
            .matching(identifier: "product-details-featured").firstMatch.exists, featured, file: file, line: line)
        XCTAssertTrue(app.staticTexts["No image available"].exists, file: file, line: line)

        let descriptionText = app.staticTexts["product-details-description"]
        for _ in 0..<10 {
            if descriptionText.exists && descriptionText.isHittable { break }
            app.scrollViews["product-details"].swipeUp()
        }
        XCTAssertEqual(descriptionText.label, description, file: file, line: line)
        XCTAssertTrue(descriptionText.isHittable, file: file, line: line)
    }

    @MainActor
    private func goBack(in app: XCUIApplication) {
        app.navigationBars["Product details"].buttons.firstMatch.tap()
    }
}
