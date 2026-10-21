import XCTest

/// Проходит по экранам с демо-данными и прикладывает скриншоты к результату.
/// Это единственный способ увидеть приложение без Mac: CI выкладывает их артефактом.
final class ScreenshotTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testAllScreensDark() throws {
        try captureAll(style: "dark")
    }

    func testAllScreensLight() throws {
        try captureAll(style: "light")
    }

    // MARK: - Обход

    private func captureAll(style: String) throws {
        let app = launch(style: style)
        for (label, name) in Self.tabs {
            let tab = app.tabBars.buttons[label]
            XCTAssertTrue(tab.waitForExistence(timeout: 15), "вкладка \(label) не найдена")
            tab.tap()
            settle()
            snap(app, "\(name)-\(style)")
        }
    }

    static let tabs: [(label: String, name: String)] = [
        ("Сейчас", "now"), ("Практики", "practices"), ("Дневник", "diary"), ("Итоги", "insights"),
    ]

    // MARK: - Помощники

    func launch(style: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--demo-data", "--ui-style", style]
        app.launch()
        return app
    }

    func settle() {
        RunLoop.current.run(until: Date().addingTimeInterval(1.2))
    }

    func snap(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
