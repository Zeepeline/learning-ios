//
//  learningUITests.swift
//  learningUITests
//
//  Created by macbook on 8/29/26.
//

import XCTest

final class learningUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// UI Test Otomatis untuk Mengambil Screenshot Semua Halaman ke folder docs/screenshots/
    @MainActor
    func testTakeAllScreenshots() throws {
        let app = XCUIApplication()
        app.launch()

        // 1. Tab Aktivitas & Tugas (Default Home)
        saveScreen(name: "01_tasks")

        // 2. Tab Hari Ini
        let todayTab = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Hari Ini'")).firstMatch
        if todayTab.waitForExistence(timeout: 3) {
            todayTab.tap()
            sleep(1)
            saveScreen(name: "02_today")
        }

        // 3. Tab Kebiasaan
        let habitTab = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Kebiasaan'")).firstMatch
        if habitTab.waitForExistence(timeout: 3) {
            habitTab.tap()
            sleep(1)
            saveScreen(name: "03_habits")
        }

        // 4. Tab Fokus (Pomodoro)
        let focusTab = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Fokus'")).firstMatch
        if focusTab.waitForExistence(timeout: 3) {
            focusTab.tap()
            sleep(1)
            saveScreen(name: "04_focus")
        }

        // 5. Tab Profil
        let profileTab = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Profil'")).firstMatch
        if profileTab.waitForExistence(timeout: 3) {
            profileTab.tap()
            sleep(1)
            saveScreen(name: "05_profile")

            // 6. Buka Edit Profil modal jika ada tombol pensil
            let editButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'pencil' OR label CONTAINS[c] 'Edit'")).firstMatch
            if editButton.waitForExistence(timeout: 2) {
                editButton.tap()
                sleep(1)
                saveScreen(name: "06_edit_profile")
                
                // Tutup sheet
                let batalButton = app.buttons["Batal"]
                if batalButton.exists {
                    batalButton.tap()
                }
            }
        }
    }

    @MainActor
    private func saveScreen(name: String) {
        let fullScreenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: fullScreenshot)
        attachment.lifetime = .keepAlways
        attachment.name = name
        add(attachment)
    }
}
