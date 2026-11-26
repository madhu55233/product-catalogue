import XCTest

final class ProductSearchTests: XCTestCase {
    @MainActor
    func testEveryMatchesOnlyBackpackAsYouTypeAndDeletingRestoresBrowsing() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        let input = app.textFields["product-search-input"]
        XCTAssertTrue(input.waitForExistence(timeout: 5))
        input.tap()
        input.typeText("Ever")
        XCTAssertTrue(app.staticTexts["Search results"].waitForExistence(timeout: 5))
        XCTAssertTrue(tile(1, in: app).exists)
        XCTAssertFalse(tile(3, in: app).exists)

        // Continue typing without re-focusing or pressing Search.
        input.typeText("y")
        XCTAssertEqual(input.value as? String, "Every")
        XCTAssertEqual(app.staticTexts["product-search-summary"].label, "1 product matching “Every”")
        XCTAssertFalse(tile(3, in: app).exists)
        XCTAssertFalse(app.staticTexts["Categories"].exists)

        input.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 5))
        XCTAssertTrue(app.staticTexts["Categories"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Search results"].exists)
    }

    @MainActor
    func testSearchButtonShowsOnlyMatchingProductsAndClearRestoresBrowsing() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        let input = app.textFields["product-search-input"]
        XCTAssertTrue(input.waitForExistence(timeout: 5))
        input.tap()
        input.typeText("SPEAKER")

        XCTAssertTrue(app.staticTexts["Search results"].waitForExistence(timeout: 5))
        XCTAssertTrue(tile(6, in: app).exists)
        app.buttons["product-search-button"].tap()

        assertResults([6], in: app)
        XCTAssertFalse(app.staticTexts["Categories"].exists)
        XCTAssertFalse(app.staticTexts["Featured products"].exists)
        XCTAssertEqual(app.staticTexts["product-search-summary"].label, "1 product matching “SPEAKER”")

        app.buttons["product-search-clear"].tap()
        XCTAssertTrue(app.staticTexts["Categories"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Featured products"].exists)
        XCTAssertFalse(app.staticTexts["Search results"].exists)
        XCTAssertFalse(app.buttons["product-search-clear"].exists)
    }

    @MainActor
    func testKeyboardSubmissionAndLiveEditingUpdateNameMatches() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        let input = app.textFields["product-search-input"]
        XCTAssertTrue(input.waitForExistence(timeout: 5))
        input.tap()
        input.typeText("backpack\n")
        assertResults([1], in: app)

        input.tap()
        input.typeText("zz")
        XCTAssertTrue(app.staticTexts["No matching products"].waitForExistence(timeout: 5))
        for id in 1...7 {
            XCTAssertFalse(tile(id, in: app).exists)
        }
        input.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 2))
        XCTAssertTrue(app.staticTexts["Search results"].waitForExistence(timeout: 5))
        XCTAssertTrue(tile(1, in: app).exists)
    }

    @MainActor
    func testSearchExcludesDescriptionOnlyMatches() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        let input = app.textFields["product-search-input"]
        XCTAssertTrue(input.waitForExistence(timeout: 5))
        input.tap()
        input.typeText("  wireless  ")
        app.buttons["product-search-button"].tap()

        assertResults([2], in: app)
        XCTAssertEqual(app.staticTexts["product-search-summary"].label, "1 product matching “wireless”")
    }

    @MainActor
    func testNoMatchesCanBeClearedAndSearchedAgain() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        let input = app.textFields["product-search-input"]
        XCTAssertTrue(input.waitForExistence(timeout: 5))
        input.tap()
        input.typeText("no-such-product")
        app.buttons["product-search-button"].tap()
        XCTAssertTrue(app.staticTexts["No matching products"].waitForExistence(timeout: 5))
        for id in 1...7 {
            XCTAssertFalse(tile(id, in: app).exists)
        }

        app.buttons["product-search-clear"].tap()
        input.tap()
        input.typeText("lamp")
        app.buttons["product-search-button"].tap()
        assertResults([4], in: app)
    }

    @MainActor
    func testSearchAtAccessibilityTextSize() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        let input = app.textFields["product-search-input"]
        XCTAssertTrue(input.waitForExistence(timeout: 5))
        input.tap()
        input.typeText("canvas")
        let search = app.buttons["product-search-button"]
        XCTAssertTrue(search.isHittable)
        search.tap()
        assertResults([7], in: app)
    }

    @MainActor
    private func tile(_ id: Int, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(identifier: "product-tile-\(id)").firstMatch
    }

    @MainActor
    private func assertResults(_ expectedIDs: [Int], in app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(app.staticTexts["Search results"].waitForExistence(timeout: 5), file: file, line: line)
        for id in expectedIDs {
            let product = tile(id, in: app)
            for _ in 0..<5 {
                if product.exists && product.isHittable { break }
                app.swipeUp()
            }
            XCTAssertTrue(product.exists, "Expected matching product \(id)", file: file, line: line)
            XCTAssertTrue(product.isHittable, file: file, line: line)
        }
        for id in (1...7) where !expectedIDs.contains(id) {
            XCTAssertFalse(tile(id, in: app).exists, "Unexpected non-matching product \(id)", file: file, line: line)
        }
    }
}
