//
//  LumaUITests.swift
//  LumaUITests
//
//  Created by Bengisu Demir on 18.02.2026.
//

import XCTest

final class LumaUITests: XCTestCase {
    private let testEmail = "test@test.com"
    private let testPassword = "123456"

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunchShowsEntryPoint() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(
            app.staticTexts["Olia"].waitForExistence(timeout: 20),
            "Uygulama giriş noktası görünmedi. Ekran özeti: \(visibleTextSummary(in: app))"
        )
    }

    @MainActor
    func testLoginWithProvidedAccountShowsHome() throws {
        let app = launchLoggedInApp()

        XCTAssertTrue(
            app.staticTexts["Keşfet"].waitForExistence(timeout: 20),
            "Login sonrası ana ekran görünmedi. Ekran özeti: \(visibleTextSummary(in: app))"
        )
        XCTAssertTrue(app.staticTexts["Klasik Masallar"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testTabNavigationSmoke() throws {
        let app = launchLoggedInApp()

        tapTab("Masal Yaz", in: app)
        XCTAssertTrue(
            app.staticTexts["Yeni Masal"].waitForExistence(timeout: 10),
            "Masal Yaz sekmesi açılmadı. Ekran özeti: \(visibleTextSummary(in: app))"
        )

        tapTab("Profil", in: app)
        XCTAssertTrue(
            app.staticTexts["Çocuk Profilleri"].waitForExistence(timeout: 10),
            "Profil sekmesi açılmadı. Ekran özeti: \(visibleTextSummary(in: app))"
        )

        tapTab("Keşfet", in: app)
        XCTAssertTrue(
            app.staticTexts["Klasik Masallar"].waitForExistence(timeout: 10),
            "Keşfet sekmesine dönülemedi. Ekran özeti: \(visibleTextSummary(in: app))"
        )
    }

    @MainActor
    func testCreateStorySmokeWithProvidedAccount() throws {
        let app = launchLoggedInApp()
        tapTab("Masal Yaz", in: app)

        XCTAssertTrue(app.staticTexts["Yeni Masal"].waitForExistence(timeout: 10))
        fillStoryPromptIfNeeded(in: app)
        tapFirstExisting(in: app, labels: ["Sihirli Masalı Yaz ✨", "Sihirli Masalı Yaz"])

        let readerOpened = app.buttons["Masalı Kaydet"].waitForExistence(timeout: 130)
            || app.staticTexts["Masalı Kaydet"].waitForExistence(timeout: 1)
        let errorShown = app.alerts["Masal oluşturulamadı"].waitForExistence(timeout: 1)

        XCTAssertTrue(
            readerOpened || errorShown,
            "Masal üretimi okuyucuya ya da görünür hata durumuna ulaşmadı. Ekran özeti: \(visibleTextSummary(in: app))"
        )
    }

    @MainActor
    func testPaywallLoadsPurchaseOptionsWithProvidedAccount() throws {
        let app = launchLoggedInApp()
        tapTab("Profil", in: app)

        if app.staticTexts["Premium üyeliğin aktif"].waitForExistence(timeout: 5) {
            XCTAssertTrue(true, "Test hesabında premium zaten aktif.")
            return
        }

        let paywallEntry = app.buttons["profile.openPaywall"].firstMatch
        XCTAssertTrue(
            paywallEntry.waitForExistence(timeout: 12),
            "Premium giriş kartı bulunamadı. Ekran özeti: \(visibleTextSummary(in: app))"
        )
        paywallEntry.tap()

        XCTAssertTrue(
            app.staticTexts["paywall.heroTitle"].waitForExistence(timeout: 15),
            "Paywall açılmadı. Ekran özeti: \(visibleTextSummary(in: app))"
        )

        let purchaseButton = app.buttons["paywall.purchase.primary"].firstMatch
        XCTAssertTrue(
            purchaseButton.waitForExistence(timeout: 45),
            "Satın alma CTA'sı bulunamadı. Ekran özeti: \(visibleTextSummary(in: app))"
        )
        XCTAssertTrue(
            purchaseButton.isEnabled,
            "RevenueCat paketleri yüklenmedi veya seçili plan satın alınabilir değil. Ekran özeti: \(visibleTextSummary(in: app))"
        )
        XCTAssertFalse(
            app.staticTexts["Paketler şu an yüklenemedi. Lütfen internet bağlantını kontrol edip tekrar dene."].exists,
            "Paywall paket yükleme hatası gösteriyor."
        )
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }

    @MainActor
    private func launchLoggedInApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launch()
        completeOnboardingIfNeeded(in: app)
        loginIfNeeded(in: app)
        return app
    }

    @MainActor
    private func completeOnboardingIfNeeded(in app: XCUIApplication) {
        if app.buttons["Atla"].waitForExistence(timeout: 3) {
            app.buttons["Atla"].tap()
            return
        }

        if app.buttons["Başlayalım"].waitForExistence(timeout: 3) {
            app.buttons["Başlayalım"].tap()
            if app.buttons["Atla"].waitForExistence(timeout: 8) {
                app.buttons["Atla"].tap()
            }
        }
    }

    @MainActor
    private func loginIfNeeded(in app: XCUIApplication) {
        guard app.buttons["Masala Başla"].waitForExistence(timeout: 15) else { return }

        let emailField = app.textFields.firstMatch
        XCTAssertTrue(emailField.waitForExistence(timeout: 5), "E-posta alanı bulunamadı.")
        emailField.tap()
        emailField.typeText(testEmail)

        let passwordField = app.secureTextFields.firstMatch
        XCTAssertTrue(passwordField.waitForExistence(timeout: 5), "Şifre alanı bulunamadı.")
        passwordField.tap()
        passwordField.typeText(testPassword)

        if app.buttons["Kapat"].waitForExistence(timeout: 2) {
            app.buttons["Kapat"].tap()
        }
        XCTAssertTrue(app.buttons["Masala Başla"].waitForExistence(timeout: 5), "Login CTA bulunamadı.")
        app.buttons["Masala Başla"].tap()
    }

    @MainActor
    private func fillStoryPromptIfNeeded(in app: XCUIApplication) {
        if app.textFields.firstMatch.waitForExistence(timeout: 5) {
            let nameField = app.textFields.firstMatch
            nameField.tap()
            nameField.typeText("Deniz")
        }

        if app.textFields.count > 1 {
            let detailsField = app.textFields.element(boundBy: 1)
            detailsField.tap()
            detailsField.typeText("Ucan hali ve konusan kedi")
        }

        if app.buttons["Kapat"].waitForExistence(timeout: 2) {
            app.buttons["Kapat"].tap()
        }
    }

    @MainActor
    private func tapTab(_ label: String, in app: XCUIApplication) {
        tapFirstExisting(in: app, labels: [label])
    }

    @MainActor
    private func tapFirstExisting(in app: XCUIApplication, labels: [String]) {
        for label in labels {
            if app.buttons[label].waitForExistence(timeout: 5) {
                app.buttons[label].tap()
                return
            }
            if app.staticTexts[label].waitForExistence(timeout: 1) {
                app.staticTexts[label].tap()
                return
            }
        }
        XCTFail("Beklenen kontrollerden biri bulunamadı: \(labels.joined(separator: ", ")). Ekran özeti: \(visibleTextSummary(in: app))")
    }

    @MainActor
    private func visibleTextSummary(in app: XCUIApplication) -> String {
        let texts = app.staticTexts.allElementsBoundByIndex
            .prefix(24)
            .map { $0.label }
            .filter { !$0.isEmpty }
        let buttons = app.buttons.allElementsBoundByIndex
            .prefix(16)
            .map { $0.label }
            .filter { !$0.isEmpty }
        return (Array(texts) + Array(buttons)).joined(separator: " | ")
    }
}
