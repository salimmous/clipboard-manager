import Foundation
import AppKit
import CoreGraphics
import ApplicationServices
import UserNotifications

public final class PasteService {
    public static let shared = PasteService()

    private var didWarnMissingAccessibility = false

    private init() {}

    public var hasAccessibilityPermission: Bool {
        AXIsProcessTrusted()
    }

    @discardableResult
    public func requestAccessibilityPermission() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    public func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    /// Copies item to clipboard and performs synthetic ⌘V keypress into the previously active application.
    public func pasteDirectly(_ item: ClipboardItem, manager: ClipboardManager) {
        let targetApp = manager.previousFrontmostApp
        manager.copyToClipboard(item)
        manager.hideWindow()

        performDirectPaste(into: targetApp)
    }

    /// Copies plain text without formatting to NSPasteboard (without triggering duplicate capture) and pastes.
    public func pasteAsPlainText(_ item: ClipboardItem, manager: ClipboardManager) {
        let plainText: String
        switch item.type {
        case .text, .url:
            plainText = item.content
        case .image:
            plainText = item.ocrText ?? ""
        }

        guard !plainText.isEmpty else { return }

        let targetApp = manager.previousFrontmostApp
        manager.copyPlainTextToClipboard(plainText)
        manager.hideWindow()

        performDirectPaste(into: targetApp)
    }

    private func performDirectPaste(into targetApp: NSRunningApplication?) {
        guard hasAccessibilityPermission else {
            notifyMissingAccessibilityIfNeeded()
            return
        }

        if let targetApp,
           !targetApp.isTerminated,
           targetApp.bundleIdentifier != Bundle.main.bundleIdentifier {
            targetApp.activate(options: [])
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            self.simulateCommandV()
        }
    }

    private func notifyMissingAccessibilityIfNeeded() {
        guard !didWarnMissingAccessibility else { return }
        didWarnMissingAccessibility = true

        let content = UNMutableNotificationContent()
        content.title = "Copied to Clipboard"
        content.body = "Enable Accessibility permission in Settings for automatic ⌘V direct paste."
        let request = UNNotificationRequest(identifier: "AccessibilityHint", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    private func simulateCommandV() {
        let vKeyCode: CGKeyCode = 0x09 // 'V'
        let source = CGEventSource(stateID: .combinedSessionState)

        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: true)
        keyDown?.flags = .maskCommand

        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: false)
        keyUp?.flags = .maskCommand

        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }
}
