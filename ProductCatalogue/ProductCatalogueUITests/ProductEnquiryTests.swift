import XCTest

final class ProductEnquiryTests: XCTestCase {
    @MainActor
    func testEnquireOpensProductFormAndRequiredFieldsAreValidated() {
        continueAfterFailure = false
        let app = openEnquiry()
        XCTAssertEqual(app.staticTexts["enquiry-product"].label, "Desk Lamp")
        submit(in: app)

        let nameError = app.staticTexts["Enter your name."]
        reveal(nameError, in: app, movingDown: false)
        XCTAssertTrue(nameError.exists)
        XCTAssertTrue(app.staticTexts["Enter a valid email address, such as name@example.com."].exists)
        XCTAssertFalse(app.staticTexts["Thank you"].exists)
    }

    @MainActor
    func testUnavailableEmailDeliveryShowsErrorAndKeepsContactDetails() {
        continueAfterFailure = false
        let app = openEnquiry()
        let name = app.textFields["enquiry-name"]
        name.tap()
        name.typeText("Alex Customer")
        let email = app.textFields["enquiry-email"]
        email.tap()
        email.typeText("alex@example.com")
        if app.buttons["Done"].exists { app.buttons["Done"].tap() }
        submit(in: app)

        let error = app.staticTexts["enquiry-submission-error"]
        reveal(error, in: app)
        XCTAssertTrue(error.waitForExistence(timeout: 5))
        XCTAssertTrue(error.label.contains("has not been sent"))
        XCTAssertFalse(app.staticTexts["Thank you"].exists)
        reveal(name, in: app, movingDown: false)
        XCTAssertEqual(name.value as? String, "Alex Customer")
        XCTAssertEqual(email.value as? String, "alex@example.com")
    }

    @MainActor
    func testEnquiryCanBeCancelledAtAccessibilityTextSize() {
        continueAfterFailure = false
        let app = openEnquiry(accessibilityTextSize: true)
        let name = app.textFields["enquiry-name"]
        reveal(name, in: app)
        name.tap()
        name.typeText("Alex")
        app.buttons["enquiry-cancel"].tap()
        XCTAssertTrue(app.navigationBars["Product details"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.navigationBars["Product enquiry"].exists)
        XCTAssertTrue(app.buttons["product-enquire-button"].exists)
    }

    @MainActor
    private func openEnquiry(accessibilityTextSize: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        if accessibilityTextSize {
            app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        }
        app.launch()
        let search = app.textFields["product-search-input"]
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("lamp")
        app.buttons["product-search-button"].tap()
        let tile = app.buttons["product-tile-4"]
        reveal(tile, in: app)
        tile.tap()
        XCTAssertTrue(app.navigationBars["Product details"].waitForExistence(timeout: 5))
        let enquire = app.buttons["product-enquire-button"]
        XCTAssertTrue(enquire.waitForExistence(timeout: 5))
        enquire.tap()
        XCTAssertTrue(app.navigationBars["Product enquiry"].waitForExistence(timeout: 5))
        return app
    }

    @MainActor
    private func submit(in app: XCUIApplication) {
        let button = app.buttons["enquiry-submit"]
        reveal(button, in: app)
        button.tap()
    }

    @MainActor
    private func reveal(_ element: XCUIElement, in app: XCUIApplication, movingDown: Bool = true) {
        for _ in 0..<8 {
            if element.exists && element.isHittable { return }
            if movingDown { app.swipeUp() } else { app.swipeDown() }
        }
        XCTAssertTrue(element.exists)
        XCTAssertTrue(element.isHittable)
    }
}
