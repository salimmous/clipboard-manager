import Foundation
import AppKit
import CoreGraphics

class PasteService {
    static let shared = PasteService()
    
    private init() {}
    
    /// Copies item to clipboard and performs synthetic ⌘V keypress into active frontmost application.
    func pasteDirectly(_ item: ClipboardItem, manager: ClipboardManager) {
        manager.copyToClipboard(item)
        manager.hideWindow()
        
        // Brief delay to allow window to dismiss and frontmost application to regain focus
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            self.simulateCommandV()
        }
    }
    
    /// Copies text without formatting to NSPasteboard and optionally pastes.
    func pasteAsPlainText(_ item: ClipboardItem, manager: ClipboardManager) {
        let plainText: String
        switch item.type {
        case .text, .url:
            plainText = item.content
        case .image:
            plainText = item.ocrText ?? ""
        }
        
        guard !plainText.isEmpty else { return }
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(plainText, forType: .string)
        
        manager.hideWindow()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            self.simulateCommandV()
        }
    }
    
    /// Synthesizes Command+V keystroke using CoreGraphics CGEvent API.
    private func simulateCommandV() {
        let vKeyCode: CGKeyCode = 0x09 // Virtual key code for 'V'
        
        let source = CGEventSource(stateID: .combinedSessionState)
        
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: true)
        keyDown?.flags = .maskCommand
        
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: false)
        keyUp?.flags = .maskCommand
        
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }
}
