import XCTest
import AppKit
@testable import ClipboardManagerCore

final class ClipboardManagerTests: XCTestCase {
    private var tempDir: URL!
    private var defaultsSuiteName: String!
    private var testDefaults: UserDefaults!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("ClipboardManagerTests-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        defaultsSuiteName = "com.clipboardmanager.tests.\(UUID().uuidString)"
        testDefaults = UserDefaults(suiteName: defaultsSuiteName)!
        testDefaults.removePersistentDomain(forName: defaultsSuiteName)
    }

    override func tearDown() {
        testDefaults.removePersistentDomain(forName: defaultsSuiteName)
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    private func makeTestImageData(width: Int = 24, height: Int = 16) -> Data {
        let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: width,
            pixelsHigh: height,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .calibratedRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        )!
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        NSColor.systemBlue.setFill()
        NSRect(x: 0, y: 0, width: width, height: height).fill()
        NSGraphicsContext.restoreGraphicsState()
        return rep.tiffRepresentation!
    }

    // MARK: - AppSettings Tests

    func testAppSettingsPreservesTrueDefaultsOnFirstLaunch() {
        let settings = AppSettings(defaults: testDefaults, enableSideEffects: false)

        XCTAssertTrue(settings.autoUpdateEnabled)
        XCTAssertTrue(settings.showNotifications)
        XCTAssertTrue(settings.watchScreenshots)
        XCTAssertTrue(settings.enableSmartDetection)
        XCTAssertTrue(settings.isPasswordManagerExclusionEnabled)
        XCTAssertTrue(settings.ignoreConcealedPasteboard)
        XCTAssertTrue(settings.isOCREnabled)
        XCTAssertTrue(settings.isDirectPasteEnabled)
        XCTAssertTrue(settings.openNearCursor)
        XCTAssertTrue(settings.preservePinnedOnClear)
        XCTAssertEqual(settings.hotkeyOption, .cmdShiftV)
        XCTAssertEqual(settings.maxItems, 100)
    }

    func testAppSettingsPersistenceAndClamping() {
        let settings = AppSettings(defaults: testDefaults, enableSideEffects: false)
        settings.maxItems = 9999
        XCTAssertEqual(settings.maxItems, 500)
        settings.maxItems = 5
        XCTAssertEqual(settings.maxItems, 20)
        settings.maxItems = 250

        settings.autoUpdateEnabled = false
        settings.hotkeyOption = .optCmdV
        settings.addIgnoredBundleID("com.example.secret")
        settings.addIgnoredBundleID("com.example.secret") // duplicate ignored

        let reloaded = AppSettings(defaults: testDefaults, enableSideEffects: false)
        XCTAssertEqual(reloaded.maxItems, 250)
        XCTAssertFalse(reloaded.autoUpdateEnabled)
        XCTAssertEqual(reloaded.hotkeyOption, .optCmdV)
        XCTAssertEqual(reloaded.ignoredBundleIDs.filter { $0 == "com.example.secret" }.count, 1)

        reloaded.removeIgnoredBundleID("com.example.secret")
        XCTAssertFalse(reloaded.ignoredBundleIDs.contains("com.example.secret"))
    }

    // MARK: - SmartDetector Tests

    func testURLValidationModernTLDsAndFalsePositives() {
        XCTAssertTrue(SmartDetector.isValidURL("https://github.com/salimmous/clipboard-manager"))
        XCTAssertTrue(SmartDetector.isValidURL("http://localhost:3000/api"))
        XCTAssertTrue(SmartDetector.isValidURL("https://example.dev/docs"))
        XCTAssertTrue(SmartDetector.isValidURL("https://tool.ai"))
        XCTAssertTrue(SmartDetector.isValidURL("https://service.ma/path"))
        XCTAssertTrue(SmartDetector.isValidURL("www.apple.com"))

        XCTAssertFalse(SmartDetector.isValidURL("visit example.com for details"))
        XCTAssertFalse(SmartDetector.isValidURL("hello world"))
        XCTAssertFalse(SmartDetector.isValidURL("user@example.com"))
        XCTAssertFalse(SmartDetector.isValidURL(""))
    }

    func testHexColorParsing() {
        let short = SmartDetector.parseHexColor("#F0A")
        XCTAssertNotNil(short)
        XCTAssertEqual(short?.r ?? -1, 1.0, accuracy: 0.001)
        XCTAssertEqual(short?.g ?? -1, 0.0, accuracy: 0.001)

        let full = SmartDetector.parseHexColor("#FF5733")
        XCTAssertNotNil(full)
        XCTAssertEqual(full?.r ?? -1, 1.0, accuracy: 0.001)

        let alpha = SmartDetector.parseHexColor("#11223380")
        XCTAssertNotNil(alpha)
        XCTAssertEqual(alpha?.a ?? -1, 128.0 / 255.0, accuracy: 0.001)

        XCTAssertNil(SmartDetector.parseHexColor("#12345"))
        XCTAssertNil(SmartDetector.parseHexColor("FF5733"))
        XCTAssertNil(SmartDetector.parseHexColor("#GGGGGG"))
    }

    func testSmartEntityDetectionDeduplicatesPhones() {
        let text = "Contact dev@example.com or call (415) 555-1234 at 123 Main Street with color #3B82F6"
        let entities = SmartDetector.detectEntities(in: text)

        XCTAssertEqual(entities.filter { $0.type == .email }.map(\.value), ["dev@example.com"])
        XCTAssertEqual(entities.filter { $0.type == .phone }.count, 1)
        XCTAssertEqual(entities.filter { $0.type == .address }.count, 1)
        XCTAssertEqual(entities.filter { $0.type == .color }.map(\.value), ["#3B82F6"])
    }

    // MARK: - ClipboardItem Codable Tests

    func testClipboardItemBackwardCompatibleDecoding() throws {
        let legacyJSON = """
        {
          "id": "11111111-2222-3333-4444-555555555555",
          "content": "Legacy text",
          "type": "text",
          "isPinned": true,
          "timestamp": 0
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(ClipboardItem.self, from: legacyJSON)
        XCTAssertEqual(decoded.content, "Legacy text")
        XCTAssertTrue(decoded.isPinned)
        XCTAssertNil(decoded.sourceAppName)
        XCTAssertNil(decoded.ocrText)

        let colorItem = ClipboardItem(content: "#FF5733")
        XCTAssertNotNil(colorItem.hexColorSwatch)
    }

    // MARK: - ImageStorageManager Tests

    func testImageStorageCompressesTIFFToPNGCachesAndCleansOrphans() {
        let imgDir = tempDir.appendingPathComponent("Images", isDirectory: true)
        let storage = ImageStorageManager(directory: imgDir)

        let tiffData = makeTestImageData(width: 40, height: 20)
        guard let saved = storage.saveImageWithMetadata(tiffData) else {
            return XCTFail("Failed to save image")
        }

        XCTAssertTrue(saved.fileName.hasSuffix(".png"))
        XCTAssertEqual(saved.width, 40)
        XCTAssertEqual(saved.height, 20)
        XCTAssertLessThan(saved.byteCount, tiffData.count)

        let exp = expectation(description: "Thumbnail loaded")
        storage.loadThumbnail(fileName: saved.fileName) { thumb in
            XCTAssertNotNil(thumb)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 2.0)
        XCTAssertNotNil(storage.cachedThumbnail(fileName: saved.fileName))

        // Add an orphan file and verify cleanup
        let orphanURL = imgDir.appendingPathComponent("orphan.png")
        try? Data([1, 2, 3]).write(to: orphanURL)
        storage.cleanupOrphanedImages(keeping: [saved.fileName])
        XCTAssertFalse(FileManager.default.fileExists(atPath: orphanURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: imgDir.appendingPathComponent(saved.fileName).path))

        storage.deleteImage(fileName: saved.fileName)
        XCTAssertNil(storage.cachedThumbnail(fileName: saved.fileName))
        XCTAssertNil(storage.loadImageData(fileName: saved.fileName))
    }

    // MARK: - ClipboardManager Core & Security Tests

    func testConcealedAndPasswordManagerAndPauseFiltering() {
        let settings = AppSettings(defaults: testDefaults, enableSideEffects: false)
        let storage = ImageStorageManager(directory: tempDir.appendingPathComponent("Images", isDirectory: true))
        let historyURL = tempDir.appendingPathComponent("history.json")
        let manager = ClipboardManager(
            settings: settings,
            imageStorage: storage,
            historyFileURL: historyURL,
            legacyDefaults: testDefaults,
            enableRuntimeSideEffects: false
        )

        XCTAssertTrue(manager.shouldIgnorePasteboard(
            types: [NSPasteboard.PasteboardType("org.nspasteboard.ConcealedType"), .string],
            frontmostBundleID: "com.apple.Safari"
        ))
        XCTAssertTrue(manager.shouldIgnorePasteboard(
            types: [NSPasteboard.PasteboardType("org.nspasteboard.TransientType"), .string],
            frontmostBundleID: "com.apple.Safari"
        ))
        XCTAssertTrue(manager.shouldIgnorePasteboard(
            types: [.string],
            frontmostBundleID: "com.1password.1password"
        ))
        XCTAssertFalse(manager.shouldIgnorePasteboard(
            types: [.string],
            frontmostBundleID: "com.apple.Safari"
        ))

        manager.pauseMonitoring(for: 60)
        XCTAssertTrue(manager.isPaused)
        XCTAssertNotNil(manager.pauseUntil)
        XCTAssertTrue(manager.shouldIgnorePasteboard(types: [.string], frontmostBundleID: "com.apple.Safari"))

        manager.resumeMonitoring()
        XCTAssertFalse(manager.isPaused)
        XCTAssertNil(manager.pauseUntil)
    }

    func testMaxItemsProtectsPinnedAndDeletesEvictedImages() {
        let settings = AppSettings(defaults: testDefaults, enableSideEffects: false)
        settings.maxItems = 20
        let imgDir = tempDir.appendingPathComponent("Images", isDirectory: true)
        let storage = ImageStorageManager(directory: imgDir)
        let historyURL = tempDir.appendingPathComponent("history.json")

        let manager = ClipboardManager(
            settings: settings,
            imageStorage: storage,
            historyFileURL: historyURL,
            legacyDefaults: testDefaults,
            enableRuntimeSideEffects: false
        )

        // Add oldest image (will be evicted) + pinned text
        manager.addImageItem(imageData: makeTestImageData())
        let evictedFileName = manager.items.first?.imageFileName
        XCTAssertNotNil(evictedFileName)

        manager.addTextItem(content: "Pinned Secret Note")
        let pinnedItem = manager.items.first!
        manager.togglePin(for: pinnedItem)

        // Fill beyond maxItems (20)
        for i in 1...25 {
            manager.addTextItem(content: "Entry \(i)")
        }

        XCTAssertEqual(manager.items.count, 20)
        XCTAssertTrue(manager.items.contains(where: { $0.content == "Pinned Secret Note" && $0.isPinned }))
        if let evictedFileName {
            XCTAssertNil(storage.loadImageData(fileName: evictedFileName), "Evicted image should be deleted from disk")
        }

        // Clear unpinned should preserve pinned
        manager.clearUnpinnedItems()
        XCTAssertEqual(manager.items.count, 1)
        XCTAssertEqual(manager.items.first?.content, "Pinned Secret Note")
    }

    func testLegacyUserDefaultsMigrationToJSONFile() throws {
        let legacyItems = [ClipboardItem(content: "Migrated entry", isPinned: true)]
        let data = try JSONEncoder().encode(legacyItems)
        testDefaults.set(data, forKey: "ClipboardItems")

        let settings = AppSettings(defaults: testDefaults, enableSideEffects: false)
        let storage = ImageStorageManager(directory: tempDir.appendingPathComponent("Images", isDirectory: true))
        let historyURL = tempDir.appendingPathComponent("history.json")

        let manager = ClipboardManager(
            settings: settings,
            imageStorage: storage,
            historyFileURL: historyURL,
            legacyDefaults: testDefaults,
            enableRuntimeSideEffects: false
        )

        XCTAssertEqual(manager.items.count, 1)
        XCTAssertEqual(manager.items.first?.content, "Migrated entry")
        XCTAssertTrue(FileManager.default.fileExists(atPath: historyURL.path))
        XCTAssertNil(testDefaults.data(forKey: "ClipboardItems"))
    }

    // MARK: - AppUpdateManager Version Comparison Tests

    func testVersionComparison() {
        XCTAssertTrue(AppUpdateManager.isNewerVersion("v1.3.3", than: "1.3.2"))
        XCTAssertTrue(AppUpdateManager.isNewerVersion("1.4.0", than: "1.3.2"))
        XCTAssertTrue(AppUpdateManager.isNewerVersion("2.0", than: "1.9.9"))
        XCTAssertFalse(AppUpdateManager.isNewerVersion("v1.3.2", than: "1.3.2"))
        XCTAssertFalse(AppUpdateManager.isNewerVersion("1.3.1", than: "1.3.2"))
        XCTAssertFalse(AppUpdateManager.isNewerVersion("1.2.9", than: "1.3.2"))
    }

    // MARK: - ScheduledClear & Integration Tests

    func testScheduledClearRemovesOldUnpinnedAndDeletesImages() {
        let settings = AppSettings(defaults: testDefaults, enableSideEffects: false)
        let imgDir = tempDir.appendingPathComponent("Images", isDirectory: true)
        let storage = ImageStorageManager(directory: imgDir)
        let historyURL = tempDir.appendingPathComponent("history.json")

        let manager = ClipboardManager(
            settings: settings,
            imageStorage: storage,
            historyFileURL: historyURL,
            legacyDefaults: testDefaults,
            enableRuntimeSideEffects: false
        )

        let saved = storage.saveImageWithMetadata(makeTestImageData())!
        let oldDate = Date().addingTimeInterval(-48 * 3600)
        let oldImage = ClipboardItem(
            id: UUID(),
            content: "Image",
            type: .image,
            isPinned: false,
            timestamp: oldDate,
            imageFileName: saved.fileName,
            detectedEntities: []
        )
        let oldPinned = ClipboardItem(
            id: UUID(),
            content: "Old Pinned",
            type: .text,
            isPinned: true,
            timestamp: oldDate,
            imageFileName: nil,
            detectedEntities: []
        )
        let fresh = ClipboardItem(content: "Fresh")

        manager.items = [oldPinned, fresh, oldImage]

        let removed = manager.removeItems(olderThan: Date().addingTimeInterval(-24 * 3600), preservePinned: true)
        XCTAssertEqual(removed, 1)
        XCTAssertEqual(manager.items.count, 2)
        XCTAssertNil(storage.loadImageData(fileName: saved.fileName))
    }

    func testIntegrationWebhookValidationAndDefaults() {
        let integrations = IntegrationManager(defaults: testDefaults)
        XCTAssertFalse(integrations.isSlackConfigured)
        XCTAssertFalse(integrations.isDiscordConfigured)

        integrations.slackWebhookURL = "http://insecure.example.com/hook"
        XCTAssertFalse(integrations.isSlackConfigured)

        integrations.slackWebhookURL = "https://hooks.slack.com/services/T00/B00/XXX"
        integrations.discordWebhookURL = "https://discord.com/api/webhooks/123/abc"
        XCTAssertTrue(integrations.isSlackConfigured)
        XCTAssertTrue(integrations.isDiscordConfigured)

        let reloaded = IntegrationManager(defaults: testDefaults)
        XCTAssertEqual(reloaded.slackWebhookURL, "https://hooks.slack.com/services/T00/B00/XXX")
        XCTAssertEqual(reloaded.discordWebhookURL, "https://discord.com/api/webhooks/123/abc")
    }
}
