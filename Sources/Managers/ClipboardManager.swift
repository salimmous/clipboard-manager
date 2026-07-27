import Foundation
import SwiftUI
import AppKit
import UserNotifications
import Carbon

class ClipboardManager: ObservableObject {
    static let shared = ClipboardManager()
    
    @Published var items: [ClipboardItem] = []
    @Published var isWindowVisible = false
    @Published var selectedPreviewItem: ClipboardItem? = nil
    
    private var timer: Timer?
    private var lastChangeCount: Int = 0
    private var clipboardWindow: NSWindow?
    private let maxItems = 100
    
    @Published var iCloudSync: iCloudSyncManager!
    @Published var scheduledClear: ScheduledClearManager!
    @Published var integrations: IntegrationManager!
    @Published var screenshotWatcher: ScreenshotWatcher!
    
    private init() {
        DispatchQueue.main.async {
            self.iCloudSync = iCloudSyncManager()
            self.scheduledClear = ScheduledClearManager(clipboardManager: self)
            self.integrations = IntegrationManager()
            self.screenshotWatcher = ScreenshotWatcher()
            self.updateScreenshotWatching()
        }
        
        loadItems()
        setupGlobalHotkey()
        startMonitoring()
    }
    
    func setupGlobalHotkey() {
        let hotKeyId = EventHotKeyID(signature: OSType(0x4D43), id: 1)
        var eventHotKey: EventHotKeyRef?
        
        let status = RegisterEventHotKey(
            UInt32(kVK_ANSI_X),
            UInt32(cmdKey),
            hotKeyId,
            GetApplicationEventTarget(),
            0,
            &eventHotKey
        )
        
        if status != noErr {
            print("Failed to register global hotkey")
        }
    }
    
    func startMonitoring() {
        lastChangeCount = NSPasteboard.general.changeCount
        let settings = AppSettings()
        timer = Timer.scheduledTimer(withTimeInterval: settings.updateInterval, repeats: true) { _ in
            self.checkClipboard()
        }
    }
    
    func restartMonitoring() {
        timer?.invalidate()
        startMonitoring()
    }
    
    func updateScreenshotWatching() {
        let settings = AppSettings()
        if settings.watchScreenshots {
            screenshotWatcher?.startWatching()
        } else {
            screenshotWatcher?.stopWatching()
        }
    }
    
    private func checkClipboard() {
        let pasteboard = NSPasteboard.general
        if pasteboard.changeCount != lastChangeCount {
            lastChangeCount = pasteboard.changeCount
            
            let settings = AppSettings()
            
            // Check Password Manager Security & Privacy Exclusion
            if settings.isPasswordManagerExclusionEnabled {
                if let frontmostApp = NSWorkspace.shared.frontmostApplication?.bundleIdentifier {
                    if settings.ignoredBundleIDs.contains(frontmostApp) {
                        print("Clipboard copying skipped from ignored sensitive app: \(frontmostApp)")
                        return
                    }
                }
            }
            
            // Check for images (PNG, TIFF, direct NSImage, or copied image files)
            if let imageData = extractImageData(from: pasteboard) {
                addImageItem(imageData: imageData)
            }
            // Check for text content
            else if let string = pasteboard.string(forType: .string), !string.isEmpty {
                if isValidURL(string) {
                    addURLItem(url: string)
                } else {
                    addTextItem(content: string)
                }
            }
        }
    }
    
    private func extractImageData(from pasteboard: NSPasteboard) -> Data? {
        // 1. Direct PNG or TIFF pasteboard data
        if let pngData = pasteboard.data(forType: .png) {
            return pngData
        }
        if let tiffData = pasteboard.data(forType: .tiff) {
            return tiffData
        }
        
        // 2. NSImage instance from pasteboard
        if pasteboard.canReadObject(forClasses: [NSImage.self], options: nil),
           let image = NSImage(pasteboard: pasteboard),
           let tiffData = image.tiffRepresentation {
            return tiffData
        }
        
        // 3. Copied Image file URLs (from Finder or Screenshots folder)
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] {
            for url in urls {
                let ext = url.pathExtension.lowercased()
                if ["png", "jpg", "jpeg", "heic", "webp", "tiff", "bmp"].contains(ext) {
                    if let data = try? Data(contentsOf: url) {
                        return data
                    }
                }
            }
        }
        
        return nil
    }
    
    private func addTextItem(content: String) {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        items.removeAll { $0.content == trimmedContent && $0.type == .text }
        let newItem = ClipboardItem(content: trimmedContent)
        items.insert(newItem, at: 0)
        
        if items.count > maxItems {
            items = Array(items.prefix(maxItems))
        }
        sortItems()
        saveItems()
        showSmartNotification(for: newItem)
    }
    
    private func addImageItem(imageData: Data) {
        guard let fileName = ImageStorageManager.shared.saveImage(imageData) else { return }
        
        let newItem = ClipboardItem(imageFileName: fileName)
        items.insert(newItem, at: 0)
        
        let itemId = newItem.id
        
        // Trigger Vision OCR if enabled
        let settings = AppSettings()
        if settings.isOCREnabled {
            OCRManager.shared.recognizeText(from: imageData) { [weak self] recognizedText in
                guard let self = self, let text = recognizedText else { return }
                if let index = self.items.firstIndex(where: { $0.id == itemId }) {
                    self.items[index].ocrText = text
                    self.saveItems()
                }
            }
        }
        
        if items.count > maxItems {
            let itemsToRemove = Array(items.suffix(from: maxItems))
            for item in itemsToRemove {
                if let fileName = item.imageFileName {
                    ImageStorageManager.shared.deleteImage(fileName: fileName)
                }
            }
            items = Array(items.prefix(maxItems))
        }
        sortItems()
        saveItems()
        showSmartNotification(for: newItem)
    }
    
    func addScreenshotItem(_ imageData: Data) {
        addImageItem(imageData: imageData)
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setData(imageData, forType: .tiff)
        
        lastChangeCount = pasteboard.changeCount
    }
    
    private func addURLItem(url: String) {
        let trimmedURL = url.trimmingCharacters(in: .whitespacesAndNewlines)
        items.removeAll { $0.content == trimmedURL && $0.type == .url }
        let newItem = ClipboardItem(url: trimmedURL)
        items.insert(newItem, at: 0)
        
        if items.count > maxItems {
            items = Array(items.prefix(maxItems))
        }
        sortItems()
        saveItems()
        showSmartNotification(for: newItem)
    }
    
    private func isValidURL(_ string: String) -> Bool {
        let urlPattern = "^(https?://)|(www\\.)|(\\w+\\.(com|org|net|edu|gov|mil|int|co|uk|de|fr|jp|cn|au|ca|br|in|ru|it|es|nl|se|no|dk|fi|pl|be|ch|at|cz|hu|pt|gr|tr|il|za|mx|ar|cl|pe|ve|uy|py|bo|ec|co|cr|pa|gt|hn|sv|ni|cu|do|ht|jm|tt|bb|gd|lc|vc|ag|kn|dm|bs|bz|gy|sr|fk|gl|fo|is|ie|mt|cy|lu|li|ad|mc|sm|va|si|sk|hr|ba|mk|al|bg|ro|md|ua|by|lt|lv|ee|fi|se|no|dk|is|ie|gb|fr|es|pt|it|ch|at|de|nl|be|lu|pl|cz|sk|hu|si|hr|ba|rs|me|mk|al|bg|ro|md|ua|by|lt|lv|ee)).*$"
        return string.range(of: urlPattern, options: .regularExpression) != nil
    }
    
    func addItem(content: String) {
        addTextItem(content: content)
    }
    
    func deleteAllItems() {
        for item in items {
            if let fileName = item.imageFileName {
                ImageStorageManager.shared.deleteImage(fileName: fileName)
            }
        }
        items.removeAll()
        saveItems()
    }
    
    func togglePin(for item: ClipboardItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index].isPinned.toggle()
            sortItems()
            saveItems()
        }
    }
    
    private func sortItems() {
        items.sort { first, second in
            if first.isPinned != second.isPinned {
                return first.isPinned
            }
            return false
        }
    }
    
    func copyToClipboard(_ item: ClipboardItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        switch item.type {
        case .text, .url:
            pasteboard.setString(item.content, forType: .string)
        case .image:
            if let imageData = item.imageData {
                pasteboard.setData(imageData, forType: .tiff)
            }
        }
        
        lastChangeCount = pasteboard.changeCount
    }
    
    func removeItem(_ item: ClipboardItem) {
        if let fileName = item.imageFileName {
            ImageStorageManager.shared.deleteImage(fileName: fileName)
        }
        items.removeAll { $0.id == item.id }
        saveItems()
    }
    
    func saveItems() {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: "ClipboardItems")
            UserDefaults.standard.synchronize()
        }
    }
    
    private func loadItems() {
        if let data = UserDefaults.standard.data(forKey: "ClipboardItems"),
           let decodedItems = try? JSONDecoder().decode([ClipboardItem].self, from: data) {
            items = decodedItems
        }
    }
    
    func mergeRemoteItems(_ remoteItems: [ClipboardItem]) {
        var mergedItems = items
        
        for remoteItem in remoteItems {
            if !mergedItems.contains(where: { $0.id == remoteItem.id }) {
                mergedItems.append(remoteItem)
            }
        }
        
        mergedItems.sort { $0.timestamp > $1.timestamp }
        
        if mergedItems.count > maxItems {
            mergedItems = Array(mergedItems.prefix(maxItems))
        }
        
        items = mergedItems
        saveItems()
    }
    
    func toggleWindow() {
        DispatchQueue.main.async {
            self.isWindowVisible ? self.hideWindow() : self.showWindow()
        }
    }
    
    func showWindow() {
        let settings = AppSettings()
        let windowSize = settings.compactMode ? 
            CGSize(width: 380, height: 400) : 
            CGSize(width: 420, height: 450)
            
        if clipboardWindow == nil {
            let contentView = ClipboardPopupView().environmentObject(self)
            let customWindow = ClipboardWindow(
                contentRect: NSRect(x: 0, y: 0, width: windowSize.width, height: windowSize.height),
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            customWindow.clipboardManager = self
            customWindow.contentView = NSHostingView(rootView: contentView)
            customWindow.backgroundColor = .clear
            customWindow.isOpaque = false
            customWindow.hasShadow = true
            customWindow.level = .floating
            customWindow.isMovableByWindowBackground = true
            customWindow.center()
            
            customWindow.acceptsMouseMovedEvents = true
            customWindow.isReleasedWhenClosed = false
            
            if let contentView = customWindow.contentView {
                contentView.wantsLayer = true
            }
            
            clipboardWindow = customWindow
        }
        clipboardWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.clipboardWindow?.makeKey()
            self.clipboardWindow?.orderFrontRegardless()
        }
        
        isWindowVisible = true
    }
    
    func hideWindow() {
        clipboardWindow?.orderOut(nil)
        isWindowVisible = false
    }
    
    private func showSmartNotification(for item: ClipboardItem) {
        let settings = AppSettings()
        guard settings.showNotifications else { return }
        
        let content = UNMutableNotificationContent()
        
        switch item.type {
        case .text:
            content.title = "Text Copied"
            content.body = String(item.content.prefix(50)) + (item.content.count > 50 ? "..." : "")
        case .image:
            content.title = "Image Copied"
            content.body = "Image saved to clipboard history"
        case .url:
            content.title = "URL Copied"
            content.body = item.content
        }
        
        content.sound = nil
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
