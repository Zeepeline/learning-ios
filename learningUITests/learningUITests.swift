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

    /// UI Test Otomatis untuk Mengambil Screenshot Semua Halaman dan menulis langsung ke file docs/screenshots/*.png
    @MainActor
    func testTakeAllScreenshots() throws {
        let app = XCUIApplication()
        app.launch()
        sleep(2) // Tunggu splash screen selesai

        // 1. Tab Aktivitas & Tugas (Default Home)
        saveToFile(name: "01_tasks.png")

        // 2. Tab Hari Ini (Index 1)
        let todayTab = app.buttons["tab_1"]
        if todayTab.waitForExistence(timeout: 3) {
            todayTab.tap()
            sleep(1)
            saveToFile(name: "02_today.png")
        }

        // 3. Tab Kebiasaan (Index 2)
        let habitTab = app.buttons["tab_2"]
        if habitTab.waitForExistence(timeout: 3) {
            habitTab.tap()
            sleep(1)
            saveToFile(name: "03_habits.png")
        }

        // 4. Tab Fokus (Pomodoro - Index 3)
        let focusTab = app.buttons["tab_3"]
        if focusTab.waitForExistence(timeout: 3) {
            focusTab.tap()
            sleep(1)
            saveToFile(name: "04_focus.png")
        }

        // 5. Tab Profil (Index 4)
        let profileTab = app.buttons["tab_4"]
        if profileTab.waitForExistence(timeout: 3) {
            profileTab.tap()
            sleep(1)
            saveToFile(name: "05_profile.png")

            // 6. Buka Edit Profil modal jika ada tombol pensil
            let editButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'pencil' OR label CONTAINS[c] 'Edit'")).firstMatch
            if editButton.waitForExistence(timeout: 2) {
                editButton.tap()
                sleep(1)
                saveToFile(name: "06_edit_profile.png")
                
                // Tutup sheet
                let batalButton = app.buttons["Batal"]
                if batalButton.exists {
                    batalButton.tap()
                    sleep(1)
                }
            }
        }
    }

    @MainActor
    private func saveToFile(name: String) {
        let fullScreenshot = XCUIScreen.main.screenshot()
        let pngData = fullScreenshot.pngRepresentation

        // Path folder project docs/screenshots
        let projectScreenshotDir = "/Users/herlambang/Documents/learning/ios/learning/docs/screenshots"
        let fileURL = URL(fileURLWithPath: projectScreenshotDir).appendingPathComponent(name)
        try? pngData.write(to: fileURL)
    }
}
