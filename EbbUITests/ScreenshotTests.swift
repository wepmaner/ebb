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

        // Вкладки
        for (label, name) in Self.tabs {
            let tab = app.tabBars.buttons[label]
            XCTAssertTrue(tab.waitForExistence(timeout: 15), "вкладка \(label) не найдена")
            tab.tap()
            settle()
            snap(app, "\(name)-\(style)")
        }

        // Цикл записи: шаг 1 → 2 → дыхание → 4
        app.tabBars.buttons["Сейчас"].tap()
        settle()
        let record = app.buttons["now.record"]
        XCTAssertTrue(record.waitForExistence(timeout: 10))
        record.tap()
        settle()
        snap(app, "record-step1-\(style)")
        app.buttons["record.next"].tap()
        settle()
        snap(app, "record-step2-\(style)")
        app.buttons["record.start"].tap()
        settle(2.5)
        snap(app, "breathing-\(style)")
        app.buttons["breathing.finish"].tap()
        settle()
        snap(app, "record-step4-\(style)")
        app.buttons["record.done"].tap()
        settle()

        // Открытая запись → шаг 4 с продолжением
        if let resume = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'now.openEntry.'")).allElementsBoundByIndex.first {
            resume.tap()
            settle()
            snap(app, "record-resume-\(style)")
            app.buttons["record.done"].tap()
            settle()
        }

        // Оглядка: ответ на первый вопрос
        let didNotHappen = app.buttons["Не случилось"].firstMatch
        if didNotHappen.waitForExistence(timeout: 3) {
            didNotHappen.tap()
            settle()
            snap(app, "now-fearcheck-answered-\(style)")
        }

        // Практики → дыхание: экран настройки
        app.tabBars.buttons["Практики"].tap()
        settle()
        app.buttons["practice.breathing"].tap()
        settle()
        snap(app, "practices-breathing-setup-\(style)")
        app.buttons["Закрыть"].firstMatch.tap()
        settle()

        // Дневник → детали первой записи
        app.tabBars.buttons["Дневник"].tap()
        settle()
        let firstRow = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] '·'")).firstMatch
        if firstRow.waitForExistence(timeout: 3) {
            firstRow.tap()
            settle()
            snap(app, "entry-detail-\(style)")
            app.navigationBars.buttons.element(boundBy: 0).tap()
            settle()
        }

        // Настройки
        app.tabBars.buttons["Сейчас"].tap()
        settle()
        app.buttons["Настройки"].tap()
        settle()
        snap(app, "settings-\(style)")
        app.buttons["Готово"].firstMatch.tap()
        settle()
    }

    func testOnboardingDark() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--demo-data", "--ui-style", "dark", "--onboarding", "-AppleLanguages", "(ru)", "-AppleLocale", "ru_RU"]
        app.launch()
        XCTAssertTrue(app.buttons["onboarding.fresh"].waitForExistence(timeout: 15))
        settle()
        snap(app, "onboarding-dark")
        app.buttons["onboarding.fresh"].tap()
        settle()
        XCTAssertTrue(app.tabBars.buttons["Сейчас"].waitForExistence(timeout: 10))
    }

    static let tabs: [(label: String, name: String)] = [
        ("Сейчас", "now"), ("Практики", "practices"), ("Дневник", "diary"), ("Итоги", "insights"),
    ]

    // MARK: - Помощники

    func launch(style: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--demo-data", "--ui-style", style, "-AppleLanguages", "(ru)", "-AppleLocale", "ru_RU"]
        app.launch()
        return app
    }

    func settle(_ seconds: TimeInterval = 1.2) {
        RunLoop.current.run(until: Date().addingTimeInterval(seconds))
    }

    func snap(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
