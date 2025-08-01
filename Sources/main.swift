import SwiftUI
import AppKit
import Combine
import Carbon
import UserNotifications
import CloudKit

// MARK: - Main App
@main
struct ClipboardManagerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // The MenuBarExtra is kept, but the main UI is the popup window.
        MenuBarExtra {
            MenuBarView()
                .environmentObject(ClipboardManager.shared)
        } label: {
            CustomClipboardIcon()
        }
    }
}

// MARK: - App Delegate
class AppDelegate: NSObject, NSApplicationDelegate {
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon to run as a background utility
        NSApp.setActivationPolicy(.accessory)
        
        // Start clipboard monitoring
        ClipboardManager.shared.startMonitoring()
        
        // Register global hotkey (Command+X)
        registerGlobalHotkey()
        
        // Start auto-update checking if enabled
        let settings = AppSettings()
        if settings.autoUpdateEnabled {
            AppUpdateManager.shared.startPeriodicCheck()
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        unregisterGlobalHotkey()
    }
    
    // Prevent app from terminating when last window is closed
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
    
    private func registerGlobalHotkey() {
        let hotKeyID = EventHotKeyID(signature: "CBMG".fourCharCodeValue, id: 1)
        let keyCode: UInt32 = 7 // X key
        let modifiers: UInt32 = UInt32(cmdKey)
        
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))
        
        InstallEventHandler(GetApplicationEventTarget(), { (nextHandler, theEvent, userData) -> OSStatus in
            if ClipboardManager.shared.isWindowVisible {
                ClipboardManager.shared.hideWindow()
            } else {
                ClipboardManager.shared.showWindow()
            }
            return noErr
        }, 1, &eventType, nil, &eventHandler)
        
        RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
    }
    
    private func unregisterGlobalHotkey() {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }
        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
        }
    }
}

// MARK: - Custom Clipboard Icon
struct CustomClipboardIcon: View {
    var body: some View {
        if let customImage = loadCustomIcon() {
            Image(nsImage: customImage)
                .renderingMode(.template)
        } else {
            // Fallback to system icon
            Image(systemName: "doc.on.clipboard")
        }
    }
    
    private func loadCustomIcon() -> NSImage? {
        // Try to load high-quality icons from different sources
        let iconPaths = [
            Bundle.main.path(forResource: "32", ofType: "png", inDirectory: "Assets.xcassets/AppIcon.appiconset"),
            Bundle.main.path(forResource: "16", ofType: "png", inDirectory: "Assets.xcassets/AppIcon.appiconset"),
            Bundle.main.path(forResource: "AppIcon", ofType: "icns"),
            Bundle.main.path(forResource: "clipboard-logo", ofType: "png")
        ].compactMap { $0 }
        
        for iconPath in iconPaths {
            if let logoImage = NSImage(contentsOfFile: iconPath) {
                // Resize to appropriate menu bar size
                let targetSize = NSSize(width: 18, height: 18)
                let resizedImage = NSImage(size: targetSize)
                
                resizedImage.lockFocus()
                logoImage.draw(in: NSRect(origin: .zero, size: targetSize), 
                             from: NSRect(origin: .zero, size: logoImage.size), 
                             operation: .sourceOver, 
                             fraction: 1.0)
                resizedImage.unlockFocus()
                
                resizedImage.isTemplate = true
                return resizedImage
            }
        }
        
        return createFallbackIcon()
    }
    
    private func createFallbackIcon() -> NSImage? {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size)
        
        image.lockFocus()
        
        // Draw the clipboard icon using NSBezierPath based on SVG
        let path = NSBezierPath()
        
        // Scale the SVG path to fit 18x18 size
        let scale: CGFloat = 18.0 / 24.0 // SVG is 24x24, we want 18x18
        
        // Main clipboard rectangle (scaled from SVG path)
        path.move(to: NSPoint(x: 2 * scale, y: 4 * scale))
        path.line(to: NSPoint(x: 4 * scale, y: 4 * scale))
        path.line(to: NSPoint(x: 4 * scale, y: 2 * scale))
        path.line(to: NSPoint(x: 14 * scale, y: 2 * scale))
        path.line(to: NSPoint(x: 16 * scale, y: 2 * scale))
        path.line(to: NSPoint(x: 16 * scale, y: 4 * scale))
        path.line(to: NSPoint(x: 16 * scale, y: 8 * scale))
        path.line(to: NSPoint(x: 20 * scale, y: 8 * scale))
        path.line(to: NSPoint(x: 22 * scale, y: 8 * scale))
        path.line(to: NSPoint(x: 22 * scale, y: 20 * scale))
        path.line(to: NSPoint(x: 10 * scale, y: 20 * scale))
        path.line(to: NSPoint(x: 8 * scale, y: 20 * scale))
        path.line(to: NSPoint(x: 8 * scale, y: 16 * scale))
        path.line(to: NSPoint(x: 4 * scale, y: 16 * scale))
        path.line(to: NSPoint(x: 2 * scale, y: 16 * scale))
        path.line(to: NSPoint(x: 2 * scale, y: 4 * scale))
        path.close()
        
        // Second layer
        let path2 = NSBezierPath()
        path2.move(to: NSPoint(x: 10 * scale, y: 16 * scale))
        path2.line(to: NSPoint(x: 10 * scale, y: 20 * scale))
        path2.line(to: NSPoint(x: 22 * scale, y: 20 * scale))
        path2.line(to: NSPoint(x: 22 * scale, y: 10 * scale))
        path2.line(to: NSPoint(x: 20 * scale, y: 10 * scale))
        path2.line(to: NSPoint(x: 16 * scale, y: 10 * scale))
        path2.line(to: NSPoint(x: 16 * scale, y: 16 * scale))
        path2.line(to: NSPoint(x: 10 * scale, y: 16 * scale))
        path2.close()
        
        NSColor.controlAccentColor.setFill()
        path.fill()
        path2.fill()
        
        image.unlockFocus()
        image.isTemplate = true
        
        return image
    }
}

// MARK: - App Settings
enum AppearanceMode: String, CaseIterable, Codable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    case blue = "blue"
    case purple = "purple"
    case green = "green"
    case orange = "orange"
    
    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        case .blue: return "Ocean Blue"
        case .purple: return "Purple Haze"
        case .green: return "Forest Green"
        case .orange: return "Sunset Orange"
        }
    }
    
    var accentColor: Color {
        switch self {
        case .system, .light, .dark:
            return .accentColor
        case .blue:
            return .blue
        case .purple:
            return .purple
        case .green:
            return .green
        case .orange:
            return .orange
        }
    }
    
    var backgroundGradient: LinearGradient {
        switch self {
        case .system, .light, .dark:
            return LinearGradient(colors: [Color(NSColor.controlBackgroundColor)], startPoint: .top, endPoint: .bottom)
        case .blue:
            return LinearGradient(colors: [Color.blue.opacity(0.1), Color.cyan.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .purple:
            return LinearGradient(colors: [Color.purple.opacity(0.1), Color.pink.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .green:
            return LinearGradient(colors: [Color.green.opacity(0.1), Color.mint.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .orange:
            return LinearGradient(colors: [Color.orange.opacity(0.1), Color.yellow.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

class AppSettings: ObservableObject {
    private var isLoading = true // Prevent saving during initialization
    
    @Published var appearanceMode: AppearanceMode = .system {
        didSet { if !isLoading { saveSettings() } }
    }
    @Published var maxItems: Int = 100 {
        didSet { if !isLoading { saveSettings() } }
    }
    @Published var updateInterval: Double = 0.5 { // in seconds
        didSet { if !isLoading { saveSettings() } }
    }
    @Published var autoUpdateEnabled: Bool = true {
        didSet { if !isLoading { saveSettings() } }
    }
    @Published var checkUpdateInterval: Double = 24.0 { // in hours
        didSet { if !isLoading { saveSettings() } }
    }
    @Published var autoInstallUpdates: Bool = false { // auto-install updates
        didSet { if !isLoading { saveSettings() } }
    }
    @Published var compactMode: Bool = false {
        didSet { if !isLoading { saveSettings() } }
    }
    @Published var showNotifications: Bool = true {
        didSet { if !isLoading { saveSettings() } }
    }
    
    init() {
        loadSettings()
        applyAppearanceMode()
        isLoading = false // Enable auto-saving after initial load
    }
    
    private func loadSettings() {
        // Load app settings from UserDefaults
        // These settings persist across app updates since they're stored in the user's Library folder
        if let appearanceModeString = UserDefaults.standard.string(forKey: "AppearanceMode"),
           let appearanceMode = AppearanceMode(rawValue: appearanceModeString) {
            self.appearanceMode = appearanceMode
        }
        
        let savedMaxItems = UserDefaults.standard.integer(forKey: "MaxItems")
        if savedMaxItems > 0 {
            self.maxItems = savedMaxItems
        }
        
        let savedUpdateInterval = UserDefaults.standard.double(forKey: "UpdateInterval")
        if savedUpdateInterval > 0 {
            self.updateInterval = savedUpdateInterval
        }
        
        self.autoUpdateEnabled = UserDefaults.standard.bool(forKey: "AutoUpdateEnabled")
        self.autoInstallUpdates = UserDefaults.standard.bool(forKey: "AutoInstallUpdates")
        self.compactMode = UserDefaults.standard.bool(forKey: "CompactMode")
        self.showNotifications = UserDefaults.standard.bool(forKey: "ShowNotifications")
        
        let savedCheckInterval = UserDefaults.standard.double(forKey: "CheckUpdateInterval")
        if savedCheckInterval > 0 {
            self.checkUpdateInterval = savedCheckInterval
        }
    }
    
    func saveSettings() {
        UserDefaults.standard.set(appearanceMode.rawValue, forKey: "AppearanceMode")
        UserDefaults.standard.set(maxItems, forKey: "MaxItems")
        UserDefaults.standard.set(updateInterval, forKey: "UpdateInterval")
        UserDefaults.standard.set(autoUpdateEnabled, forKey: "AutoUpdateEnabled")
        UserDefaults.standard.set(autoInstallUpdates, forKey: "AutoInstallUpdates")
        UserDefaults.standard.set(compactMode, forKey: "CompactMode")
        UserDefaults.standard.set(showNotifications, forKey: "ShowNotifications")
        UserDefaults.standard.set(checkUpdateInterval, forKey: "CheckUpdateInterval")
        
        // Force synchronization to disk immediately
        UserDefaults.standard.synchronize()
        
        applyAppearanceMode()
        
        // Restart monitoring with new interval
        ClipboardManager.shared.restartMonitoring()
        
        // Restart update checking
        if autoUpdateEnabled {
            AppUpdateManager.shared.startPeriodicCheck()
        } else {
            AppUpdateManager.shared.stopPeriodicCheck()
        }
    }
    
    private func applyAppearanceMode() {
        DispatchQueue.main.async {
            switch self.appearanceMode {
            case .system:
                NSApp.appearance = nil
            case .light, .blue, .green, .orange:
                NSApp.appearance = NSAppearance(named: .aqua)
            case .dark, .purple:
                NSApp.appearance = NSAppearance(named: .darkAqua)
            }
        }
    }
}

// MARK: - App Update Manager
class AppUpdateManager: ObservableObject {
    static let shared = AppUpdateManager()
    
    @Published var isUpdateAvailable = false
    @Published var latestVersion = ""
    @Published var downloadURL = ""
    @Published var isChecking = false
    
    private var updateTimer: Timer?
    private let currentVersion = "1.1.11"
    private let updateCheckURL = "https://api.github.com/repos/salimmous/clipboard-manager/releases/latest"
    
    private init() {}
    
    func startPeriodicCheck() {
        stopPeriodicCheck()
        let interval = TimeInterval(AppSettings().checkUpdateInterval * 3600) // convert hours to seconds
        updateTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            self.checkForUpdates()
        }
        // Immediate check on start
        checkForUpdates()
    }
    
    func stopPeriodicCheck() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    func checkForUpdates() {
        guard !isChecking else { return }
        
        isChecking = true
        
        guard let url = URL(string: updateCheckURL) else {
            isChecking = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isChecking = false
                
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let tagName = json["tag_name"] as? String,
                      let assets = json["assets"] as? [[String: Any]],
                      let firstAsset = assets.first,
                      let downloadURL = firstAsset["browser_download_url"] as? String else {
                    return
                }
                
                self?.latestVersion = tagName
                self?.downloadURL = downloadURL
                
                // Compare versions
                if self?.isNewerVersion(tagName) == true {
                    self?.isUpdateAvailable = true
                    self?.showUpdateNotification()
                }
            }
        }.resume()
    }
    
    private func isNewerVersion(_ version: String) -> Bool {
        let current = currentVersion.components(separatedBy: ".").compactMap { Int($0) }
        let latest = version.replacingOccurrences(of: "v", with: "").components(separatedBy: ".").compactMap { Int($0) }
        
        for i in 0..<max(current.count, latest.count) {
            let currentPart = i < current.count ? current[i] : 0
            let latestPart = i < latest.count ? latest[i] : 0
            
            if latestPart > currentPart {
                return true
            } else if latestPart < currentPart {
                return false
            }
        }
        return false
    }
    
    private func showUpdateNotification() {
        let notification = NSUserNotification()
        notification.title = "New Update Available"
        notification.informativeText = "Version \(latestVersion) of Clipboard Manager is now available"
        notification.soundName = NSUserNotificationDefaultSoundName
        notification.hasActionButton = true
        notification.actionButtonTitle = "Update"
        notification.otherButtonTitle = "Later"
        
        NSUserNotificationCenter.default.deliver(notification)
    }
    
    func downloadAndInstallUpdate() {
        guard let url = URL(string: downloadURL) else { return }
        
        let task = URLSession.shared.downloadTask(with: url) { [weak self] localURL, response, error in
            guard let localURL = localURL else { return }
            
            DispatchQueue.main.async {
                self?.installUpdate(from: localURL)
            }
        }
        task.resume()
    }
    
    private func installUpdate(from url: URL) {
        let settings = AppSettings()
        
        if settings.autoInstallUpdates {
            // Auto install without asking
            autoInstallAndRestart(from: url)
        } else {
            // Show installation options to user
            let alert = NSAlert()
            alert.messageText = "Install Update"
            alert.informativeText = "How would you like to install the update?"
            alert.addButton(withTitle: "Auto Install & Restart")
            alert.addButton(withTitle: "Download to Downloads")
            alert.addButton(withTitle: "Cancel")
            
            let response = alert.runModal()
            
            switch response {
            case .alertFirstButtonReturn:
                // Auto install and restart
                autoInstallAndRestart(from: url)
            case .alertSecondButtonReturn:
                // Download to Downloads folder
                downloadToDownloads(from: url)
            default:
                // Cancel - clean up
                try? FileManager.default.removeItem(at: url)
            }
        }
    }
    
    private func autoInstallAndRestart(from url: URL) {
        // Get current app bundle path
        let currentAppPath = Bundle.main.bundlePath
        let applicationsURL = URL(fileURLWithPath: "/Applications")
        let targetAppURL = applicationsURL.appendingPathComponent("ClipboardManager.app")
        
        // Create a temporary script for the installation
        let tempDir = FileManager.default.temporaryDirectory
        let scriptURL = tempDir.appendingPathComponent("install_update.sh")
        
        let script = """
        #!/bin/bash
        
        # ClipboardManager Auto-Update Installation Script
        # This script preserves all user data during the update process:
        # - Clipboard history (stored in UserDefaults)
        # - App settings and preferences (stored in UserDefaults)
        # - User data is NOT stored in the app bundle, so it remains intact
        
        # Wait for the current app to quit
        sleep 2
        
        # Mount the DMG
        hdiutil attach "\(url.path)" -quiet
        
        # Find the mounted volume
        VOLUME_PATH="/Volumes/Install ClipboardManager"
        
        if [ -d "$VOLUME_PATH" ]; then
            # Remove old app if exists (only the app bundle, user data is preserved)
            if [ -d "\(targetAppURL.path)" ]; then
                rm -rf "\(targetAppURL.path)"
            fi
            
            # Copy new app to Applications
            cp -R "$VOLUME_PATH/ClipboardManager.app" "\(applicationsURL.path)/"
            
            # Unmount DMG
            hdiutil detach "$VOLUME_PATH" -quiet
            
            # Remove downloaded DMG
            rm -f "\(url.path)"
            
            # Launch new app (user data will be automatically loaded)
            open "\(targetAppURL.path)"
        fi
        
        # Clean up script
        rm -f "\(scriptURL.path)"
        """
        
        do {
            try script.write(to: scriptURL, atomically: true, encoding: .utf8)
            
            // Make script executable
            let attributes = [FileAttributeKey.posixPermissions: 0o755]
            try FileManager.default.setAttributes(attributes, ofItemAtPath: scriptURL.path)
            
            // Show final confirmation
            let confirmAlert = NSAlert()
            confirmAlert.messageText = "Ready to Install"
            confirmAlert.informativeText = "The app will now close and automatically install the update. The new version will launch automatically."
            confirmAlert.addButton(withTitle: "Install Now")
            confirmAlert.addButton(withTitle: "Cancel")
            
            if confirmAlert.runModal() == .alertFirstButtonReturn {
                // Execute the installation script
                let task = Process()
                task.launchPath = "/bin/bash"
                task.arguments = [scriptURL.path]
                task.launch()
                
                // Quit the current app
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    NSApplication.shared.terminate(nil)
                }
            } else {
                // User cancelled, clean up
                try? FileManager.default.removeItem(at: scriptURL)
                try? FileManager.default.removeItem(at: url)
            }
            
        } catch {
            print("Error creating installation script: \(error)")
            // Fallback to Downloads folder
            downloadToDownloads(from: url)
        }
    }
    
    private func downloadToDownloads(from url: URL) {
        let downloadsPath = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
        let destinationURL = downloadsPath.appendingPathComponent("ClipboardManager-\(latestVersion)-Installer.dmg")
        
        do {
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            try FileManager.default.moveItem(at: url, to: destinationURL)
            
            // Open Downloads folder to show the new app
            NSWorkspace.shared.selectFile(destinationURL.path, inFileViewerRootedAtPath: downloadsPath.path)
            
            // Show message to user
            let alert = NSAlert()
            alert.messageText = "Update Downloaded Successfully"
            alert.informativeText = "The new version has been saved to the Downloads folder. Please install it manually when ready."
            alert.addButton(withTitle: "OK")
            alert.runModal()
            
        } catch {
            print("Error downloading update: \(error)")
        }
    }
}

// MARK: - String Extension
extension String {
    var fourCharCodeValue: FourCharCode {
        var result: FourCharCode = 0
        if let data = self.data(using: .macOSRoman) {
            data.withUnsafeBytes { bytes in
                for i in 0..<min(4, data.count) {
                    result = result << 8 + FourCharCode(bytes[i])
                }
            }
        }
        return result
    }
}

// MARK: - Clipboard Item Model
enum ClipboardItemType: String, Codable {
    case text = "text"
    case image = "image"
    case url = "url"
}

struct ClipboardItem: Identifiable, Codable, Hashable {
    let id: UUID
    let content: String
    let type: ClipboardItemType
    var isPinned: Bool
    let timestamp: Date
    var imageData: Data?
    
    // Simplified init for text
    init(content: String, isPinned: Bool = false) {
        self.id = UUID()
        self.content = content
        self.type = .text
        self.isPinned = isPinned
        self.timestamp = Date()
        self.imageData = nil
    }
    
    // Init for images
    init(imageData: Data, isPinned: Bool = false) {
        self.id = UUID()
        self.content = "Image (\(ByteCountFormatter.string(fromByteCount: Int64(imageData.count), countStyle: .file)))"
        self.type = .image
        self.isPinned = isPinned
        self.timestamp = Date()
        self.imageData = imageData
    }
    
    // Init for URLs
    init(url: String, isPinned: Bool = false) {
        self.id = UUID()
        self.content = url
        self.type = .url
        self.isPinned = isPinned
        self.timestamp = Date()
        self.imageData = nil
    }
    
    // Complete initializer for sync
    init(id: UUID, content: String, type: ClipboardItemType, isPinned: Bool, timestamp: Date, imageData: Data?) {
        self.id = id
        self.content = content
        self.type = type
        self.isPinned = isPinned
        self.timestamp = timestamp
        self.imageData = imageData
    }
    
    var displayContent: String {
        switch type {
        case .text, .url:
            return content
        case .image:
            return content // Already formatted in init
        }
    }
    
    var typeIcon: String {
        switch type {
        case .text:
            return "doc.text"
        case .image:
            return "photo"
        case .url:
            return "link"
        }
    }
}



// MARK: - Clipboard Manager
class ClipboardManager: ObservableObject {
    static let shared = ClipboardManager()
    
    @Published var items: [ClipboardItem] = []
    @Published var isWindowVisible = false
    
    private var timer: Timer?
    private var lastChangeCount: Int = 0
    private var clipboardWindow: NSWindow?
    private let maxItems = 100
    
    // Integration managers
    @Published var iCloudSync: iCloudSyncManager!
    @Published var scheduledClear: ScheduledClearManager!
    @Published var integrations: IntegrationManager!
    
    private init() {
        // Initialize managers after self is available
        DispatchQueue.main.async {
            self.iCloudSync = iCloudSyncManager()
            self.scheduledClear = ScheduledClearManager(clipboardManager: self)
            self.integrations = IntegrationManager()
        }
        
        loadItems()
        setupGlobalHotkey()
        startMonitoring()
    }
    
    func setupGlobalHotkey() {
        // Register global hotkey ⌘+X
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
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            self.checkClipboard()
        }
    }
    
    func restartMonitoring() {
        timer?.invalidate()
        startMonitoring()
    }
    
    private func checkClipboard() {
        if NSPasteboard.general.changeCount != lastChangeCount {
            lastChangeCount = NSPasteboard.general.changeCount
            
            let pasteboard = NSPasteboard.general
            
            // Check for images first
            if let imageData = pasteboard.data(forType: .tiff) ?? pasteboard.data(forType: .png) {
                addImageItem(imageData: imageData)
            }
            // Check for text content
            else if let string = pasteboard.string(forType: .string), !string.isEmpty {
                // Detect if it's a URL
                if isValidURL(string) {
                    addURLItem(url: string)
                } else {
                    addTextItem(content: string)
                }
            }
        }
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
        let newItem = ClipboardItem(imageData: imageData)
        items.insert(newItem, at: 0)
        
        if items.count > maxItems {
            items = Array(items.prefix(maxItems))
        }
        sortItems()
        saveItems()
        showSmartNotification(for: newItem)
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
            return false // Keep original order for items with same pin status
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
        items.removeAll { $0.id == item.id }
        saveItems()
    }
    
    func saveItems() {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: "ClipboardItems")
            // Force synchronization to disk immediately
            UserDefaults.standard.synchronize()
        }
    }
    
    private func loadItems() {
        // Load clipboard items from UserDefaults
        // This data persists across app updates since it's stored in the user's Library folder
        if let data = UserDefaults.standard.data(forKey: "ClipboardItems"),
           let decodedItems = try? JSONDecoder().decode([ClipboardItem].self, from: data) {
            items = decodedItems
        }
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
            customWindow.clipboardManager = self // Set the reference for key handling
            customWindow.contentView = NSHostingView(rootView: contentView)
            customWindow.backgroundColor = .clear
            customWindow.isOpaque = false
            customWindow.hasShadow = true
            customWindow.level = .floating
            customWindow.isMovableByWindowBackground = true
            customWindow.center()
            
            // Ensure window can receive key events properly
            customWindow.acceptsMouseMovedEvents = true
            customWindow.isReleasedWhenClosed = false
            
            // Enable dragging
            if let contentView = customWindow.contentView {
                contentView.wantsLayer = true
            }
            
            clipboardWindow = customWindow
        }
        clipboardWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        // Ensure the window becomes the key window for keyboard input
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
        
        let notification = NSUserNotification()
        
        switch item.type {
        case .text:
            notification.title = "Text Copied"
            notification.informativeText = String(item.content.prefix(50)) + (item.content.count > 50 ? "..." : "")
        case .image:
            notification.title = "Image Copied"
            notification.informativeText = item.content
        case .url:
            notification.title = "URL Copied"
            notification.informativeText = item.content
        }
        
        notification.soundName = nil // Silent notification
        NSUserNotificationCenter.default.deliver(notification)
        
        // Auto-remove after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            NSUserNotificationCenter.default.removeDeliveredNotification(notification)
        }
    }
}

// MARK: - Custom Window for Better Key Handling
class ClipboardWindow: NSWindow {
    var clipboardManager: ClipboardManager?
    
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // Escape key
            clipboardManager?.hideWindow()
            return
        }
        
        if event.keyCode == 36 { // Enter key
            // Let the view handle Enter key for copying items
            super.keyDown(with: event)
            return
        }
        
        // Pass other keys to the content view
        super.keyDown(with: event)
    }
    
    override var canBecomeKey: Bool {
        return true
    }
    
    override var acceptsFirstResponder: Bool {
        return true
    }
}

// MARK: - Clipboard Popup View (MODERN DESIGN)
struct ClipboardPopupView: View {
    @EnvironmentObject var clipboardManager: ClipboardManager
    @State private var selectedIndex: Int? = 0
    @State private var searchText = ""
    @State private var selectedContentType: ClipboardItemType? = nil
    @State private var showingFilters = false
    @State private var dateFilter: DateFilter = .all
    @StateObject private var appSettings = AppSettings()
    private static var settingsDelegate = SettingsWindowDelegate()
    
    enum DateFilter: String, CaseIterable {
        case all = "All Time"
        case today = "Today"
        case yesterday = "Yesterday"
        case thisWeek = "This Week"
        case thisMonth = "This Month"
    }
    
    var filteredItems: [ClipboardItem] {
        var items = clipboardManager.items
        
        // Filter by content type
        if let contentType = selectedContentType {
            items = items.filter { $0.type == contentType }
        }
        
        // Filter by date
        switch dateFilter {
        case .all:
            break
        case .today:
            items = items.filter { Calendar.current.isDateInToday($0.timestamp) }
        case .yesterday:
            items = items.filter { Calendar.current.isDateInYesterday($0.timestamp) }
        case .thisWeek:
            let weekStart = Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
            items = items.filter { $0.timestamp >= weekStart }
        case .thisMonth:
            let monthStart = Calendar.current.dateInterval(of: .month, for: Date())?.start ?? Date()
            items = items.filter { $0.timestamp >= monthStart }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            items = items.filter { $0.displayContent.localizedCaseInsensitiveContains(searchText) }
        }
        
        return items
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with title, clear button, and close button (Draggable area)
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                Text("Clipboard")
                            .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.primary)
                        
                        if !filteredItems.isEmpty {
                            Text("\(filteredItems.count)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue)
                                .clipShape(Capsule())
                        }
                    }
                    
                    if !clipboardManager.items.isEmpty {
                        Text("⌘+X to open • Esc to close")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary.opacity(0.8))
                    }
                }
                
                Spacer()
                
                // Action buttons with better styling
                HStack(spacing: 8) {
                    if !clipboardManager.items.isEmpty {
                Button("Clear all") {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    clipboardManager.items.removeAll()
                    clipboardManager.saveItems()
                }
                        }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.red)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.1))
                        .clipShape(Capsule())
                        .buttonStyle(.plain)
                    }
                
                Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            showingFilters.toggle()
                        }
                    }) {
                        Image(systemName: showingFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(hasActiveFilters ? .blue : .secondary)
                    }
                    .buttonStyle(.plain)
                    .scaleEffect(showingFilters ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showingFilters)
                    
                    Button(action: {
                        clipboardManager.hideWindow()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            openSettingsFromPopup()
                        }
                }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                
                Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    clipboardManager.hideWindow()
                        }
                }) {
                        Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 12)
            .background(
                LinearGradient(
                    colors: [
                        appSettings.appearanceMode.accentColor.opacity(0.03),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .background(DragAreaView())
            
            // Search and Filters Section
            VStack(spacing: 12) {
            // Search bar
                HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                        .font(.system(size: 14, weight: .medium))
                    
                TextField("Search clipboard...", text: $searchText)
                    .textFieldStyle(.plain)
                        .font(.system(size: 14))
                        .onSubmit {
                            // Focus first result when searching
                            if !filteredItems.isEmpty {
                                selectedIndex = 0
                            }
                        }
                    
                if !searchText.isEmpty {
                        Button(action: { 
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                searchText = ""
                            }
                        }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                                .font(.system(size: 14))
                    }
                    .buttonStyle(.plain)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(NSColor.textBackgroundColor))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(searchText.isEmpty ? Color.clear : Color.blue.opacity(0.3), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.03), radius: 1, x: 0, y: 1)
                )
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: searchText.isEmpty)
                
                // Filters (when shown)
                if showingFilters {
                    VStack(spacing: 8) {
                        // Content Type Filter
                        HStack {
                            Text("Type:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    FilterChip(
                                        title: "All",
                                        isSelected: selectedContentType == nil,
                                        action: { selectedContentType = nil }
                                    )
                                    
                                    FilterChip(
                                        title: "Text",
                                        isSelected: selectedContentType == .text,
                                        action: { selectedContentType = .text }
                                    )
                                    
                                    FilterChip(
                                        title: "Images",
                                        isSelected: selectedContentType == .image,
                                        action: { selectedContentType = .image }
                                    )
                                    
                                    FilterChip(
                                        title: "URLs",
                                        isSelected: selectedContentType == .url,
                                        action: { selectedContentType = .url }
                                    )
                                }
                                .padding(.horizontal, 4)
                            }
                        }
                        
                        // Date Filter
                        HStack {
                            Text("When:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(DateFilter.allCases, id: \.self) { filter in
                                        FilterChip(
                                            title: filter.rawValue,
                                            isSelected: dateFilter == filter,
                                            action: { dateFilter = filter }
                                        )
                                    }
                                }
                                .padding(.horizontal, 4)
                            }
                        }
                        
                        // Results count
                        HStack {
                            Text("\(filteredItems.count) items")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            if hasActiveFilters {
                                Button("Clear Filters") {
                                    selectedContentType = nil
                                    dateFilter = .all
                                    searchText = ""
                                }
                                .font(.caption)
                                .foregroundColor(.blue)
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)

            // Items List
            ScrollView {
                LazyVStack(spacing: 6) {
                    ForEach(Array(filteredItems.enumerated()), id: \.element.id) { index, item in
                        ClipboardPopupItemView(
                            item: item,
                            isSelected: selectedIndex == index
                        )
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.8).combined(with: .opacity),
                            removal: .scale(scale: 0.8).combined(with: .opacity)
                        ))
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: filteredItems.count)
                        .onTapGesture {
                            selectedIndex = index
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            clipboardManager.copyToClipboard(item)
                            }
                            
                            // Visual feedback
                            let impactFeedback = NSHapticFeedbackManager.defaultPerformer
                            impactFeedback.perform(.generic, performanceTime: .default)
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                clipboardManager.hideWindow()
                                }
                            }
                        }
                        .onHover { hovering in
                            if hovering {
                                selectedIndex = index
                            }
                        }
                        .scaleEffect(selectedIndex == index ? 1.02 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selectedIndex)
                    }
                    
                    if filteredItems.isEmpty {
                        VStack(spacing: 20) {
                            // Animated Icon
                            VStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(LinearGradient(
                                            colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ))
                                        .frame(width: 80, height: 80)
                                    
                                    Image(systemName: "doc.text.magnifyingglass")
                                        .font(.system(size: 32, weight: .medium))
                                        .foregroundColor(.blue)
                                }
                                .scaleEffect(1.0)
                                .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: UUID())
                            }
                            
                            VStack(spacing: 8) {
                                Text(emptyStateTitle)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                Text(emptyStateMessage)
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(3)
                            }
                            
                            // Quick Tips
                            if !hasActiveFilters {
                                VStack(spacing: 12) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "lightbulb.fill")
                                            .foregroundColor(.yellow)
                                            .font(.system(size: 12))
                                        Text("Quick Tips")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    VStack(spacing: 6) {
                                        TipRow(icon: "doc.on.doc", text: "Copy text to see it here instantly")
                                        TipRow(icon: "photo", text: "Copy images for quick access")
                                        TipRow(icon: "command", text: "Press ⌘+X to open clipboard")
                                        TipRow(icon: "magnifyingglass", text: "Use search to find anything")
                                    }
                                }
                                .padding(16)
                                .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(appSettings.appearanceMode.backgroundGradient)
                .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 8)
        )
        .accentColor(appSettings.appearanceMode.accentColor)
        .preferredColorScheme(nil) // Adapts to system appearance
        .onAppear {
            if !filteredItems.isEmpty {
                selectedIndex = 0
            }
        }
        .onDisappear {
            selectedIndex = nil
        }
        .onKeyDown { event in
            handleKeyDown(event)
        }
    }
    
    private var hasActiveFilters: Bool {
        selectedContentType != nil || dateFilter != .all || !searchText.isEmpty
    }
    
    private var emptyStateTitle: String {
        if hasActiveFilters {
            return "No Results Found"
        } else {
            return "Welcome to Clipboard Manager! 👋"
        }
    }
    
    private var emptyStateMessage: String {
        if hasActiveFilters {
            return "No items match your current filters.\nTry adjusting your search criteria or clear filters."
        } else {
            return "Your clipboard history will appear here.\nCopy something to get started!"
        }
    }
    
    private func handleKeyDown(_ event: NSEvent) {
        let items = filteredItems
        guard !items.isEmpty else { 
            // Even if no items, still allow Esc to close
            if event.keyCode == 53 { // Escape
                clipboardManager.hideWindow()
            }
            return 
        }
        
        switch event.keyCode {
        case 36: // Enter
            if let index = selectedIndex, index < items.count {
                clipboardManager.copyToClipboard(items[index])
                clipboardManager.hideWindow()
            }
        case 53: // Escape
            clipboardManager.hideWindow()
        case 125: // Down arrow
            if let current = selectedIndex {
                selectedIndex = min(current + 1, items.count - 1)
            } else {
                selectedIndex = 0
            }
        case 126: // Up arrow
            if let current = selectedIndex {
                selectedIndex = max(current - 1, 0)
            } else {
                selectedIndex = 0
            }
        default:
            break
        }
    }
    
    private func openSettingsFromPopup() {
        if let window = NSApp.windows.first(where: { $0.title == "Clipboard Manager Settings" }) {
            window.makeKeyAndOrderFront(nil)
        } else {
            let settings = AppSettings()
            let settingsView = SettingsView().environmentObject(settings)
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            window.center()
            window.setFrameAutosaveName("Settings")
            window.contentView = NSHostingView(rootView: settingsView)
            window.title = "Clipboard Manager Settings"
            
            // Configure window to not affect app lifecycle
            window.isReleasedWhenClosed = false  // Keep the window in memory
            window.hidesOnDeactivate = false
            window.delegate = Self.settingsDelegate  // Use custom delegate
            
            // Set window level above normal but below floating
            window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.normalWindow)) + 1)
            
            window.makeKeyAndOrderFront(nil)
        }
    }
}

// MARK: - Quick Actions
enum QuickAction {
    case uppercase
    case lowercase
    case capitalizeWords
    case removeSpaces
    case addQuotes
    case base64Encode
    case base64Decode
    case urlEncode
    case urlDecode
    case copyEmail
    case copyPhone
    case qrCode
    
    var title: String {
        switch self {
        case .uppercase: return "UPPERCASE"
        case .lowercase: return "lowercase"
        case .capitalizeWords: return "Capitalize Words"
        case .removeSpaces: return "Remove Spaces"
        case .addQuotes: return "Add Quotes"
        case .base64Encode: return "Base64 Encode"
        case .base64Decode: return "Base64 Decode"
        case .urlEncode: return "URL Encode"
        case .urlDecode: return "URL Decode"
        case .copyEmail: return "Copy as Email"
        case .copyPhone: return "Copy as Phone"
        case .qrCode: return "Generate QR Code"
        }
    }
    
    var icon: String {
        switch self {
        case .uppercase, .lowercase, .capitalizeWords: return "textformat"
        case .removeSpaces: return "minus.square"
        case .addQuotes: return "quote.bubble"
        case .base64Encode, .base64Decode: return "lock.shield"
        case .urlEncode, .urlDecode: return "link.badge.plus"
        case .copyEmail: return "envelope"
        case .copyPhone: return "phone"
        case .qrCode: return "qrcode"
        }
    }
    
    func apply(to text: String) -> String {
        switch self {
        case .uppercase:
            return text.uppercased()
        case .lowercase:
            return text.lowercased()
        case .capitalizeWords:
            return text.capitalized
        case .removeSpaces:
            return text.replacingOccurrences(of: " ", with: "")
        case .addQuotes:
            return "\"\(text)\""
        case .base64Encode:
            return Data(text.utf8).base64EncodedString()
        case .base64Decode:
            guard let data = Data(base64Encoded: text) else { return text }
            return String(data: data, encoding: .utf8) ?? text
        case .urlEncode:
            return text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? text
        case .urlDecode:
            return text.removingPercentEncoding ?? text
        case .copyEmail:
            return "mailto:\(text)"
        case .copyPhone:
            return "tel:\(text.replacingOccurrences(of: " ", with: ""))"
        case .qrCode:
            return text // QR code generation would need additional implementation
        }
    }
    
    static func availableActions(for item: ClipboardItem) -> [QuickAction] {
        switch item.type {
        case .text:
            return [.uppercase, .lowercase, .capitalizeWords, .removeSpaces, .addQuotes, .base64Encode, .urlEncode]
        case .url:
            return [.urlDecode, .qrCode]
        case .image:
            return [.qrCode]
        }
    }
}

// MARK: - Filter Chip Component
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Clipboard Popup Item View (MODERN DESIGN)
struct ClipboardPopupItemView: View {
    let item: ClipboardItem
    let isSelected: Bool
    @EnvironmentObject var clipboardManager: ClipboardManager
    
    var body: some View {
        HStack(spacing: 12) {
            // Content type icon and preview
            VStack {
                if item.type == .image, let imageData = item.imageData, let nsImage = NSImage(data: imageData) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40, height: 40)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                } else {
                    Image(systemName: item.typeIcon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(iconColor)
                        .frame(width: 40, height: 40)
                        .background(iconColor.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
            
            // Pin indicator
            if item.isPinned {
                Image(systemName: "pin.fill")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.orange)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(item.displayContent)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                        .lineLimit(item.type == .image ? 1 : 2)
                    .multilineTextAlignment(.leading)
                    
                    if item.type == .url {
                        Image(systemName: "arrow.up.right.square")
                            .font(.system(size: 12))
                            .foregroundColor(.blue)
                    }
                }
                
                HStack {
                    Text(timeAgo)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    
                    if item.isPinned {
                        Text("• Pinned")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    
                    Spacer()
                    
                    Text(item.type.rawValue.capitalized)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(iconColor.opacity(0.15))
                        .foregroundColor(iconColor)
                        .clipShape(Capsule())
                }
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 4) {
                Menu {
                    // Standard Actions Section
                    Section("Actions") {
                        if item.type == .url {
                            Button("Open in Browser") {
                                openInBrowser(item.content)
                            }
                        }
                        
                    Button("Share to WhatsApp") {
                        shareToWhatsApp(item.content)
                    }
                    
                    Button("Share to Other Apps") {
                            shareToOtherApps(item)
                        }
                    }
                    
                    // Integration Section
                    Section("Integrations") {
                        Button("Send to Slack") {
                            clipboardManager.integrations?.shareToSlack(item.content)
                        }
                        
                        Button("Send to Discord") {
                            clipboardManager.integrations?.shareToDiscord(item.content)
                        }
                        
                        Button("Compose Email") {
                            clipboardManager.integrations?.composeEmail(with: item.content)
                        }
                        
                        Button("Save to Notes") {
                            let title = String(item.content.prefix(50)) + (item.content.count > 50 ? "..." : "")
                            clipboardManager.integrations?.saveToNotes(item.content, title: title)
                        }
                    }
                    
                    Divider()
                    
                    Section("Clipboard") {
                    Button("Copy") {
                            clipboardManager.copyToClipboard(item)
                        }
                        
                        Button("Delete") {
                            clipboardManager.removeItem(item)
                        }
                             }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
                
                Button(action: {
                    clipboardManager.togglePin(for: item)
                }) {
                    Image(systemName: item.isPinned ? "pin.fill" : "pin")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(item.isPinned ? .orange : .secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.accentColor.opacity(0.15) : Color(NSColor.controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1.5)
        )
    }
    
    private var iconColor: Color {
        switch item.type {
        case .text:
            return .blue
        case .image:
            return .green
        case .url:
            return .purple
        }
    }
    
    private var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: item.timestamp, relativeTo: Date())
    }
    
    private func shareToWhatsApp(_ text: String) {
        let encodedText = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let whatsappURL = "whatsapp://send?text=\(encodedText)"
        
        if let url = URL(string: whatsappURL) {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func shareToOtherApps(_ item: ClipboardItem) {
        var itemsToShare: [Any] = []
        
        switch item.type {
        case .text, .url:
            itemsToShare = [item.content]
        case .image:
            if let imageData = item.imageData, let image = NSImage(data: imageData) {
                itemsToShare = [image]
            }
        }
        
        let sharingPicker = NSSharingServicePicker(items: itemsToShare)
        if let view = NSApp.keyWindow?.contentView {
            sharingPicker.show(relativeTo: .zero, of: view, preferredEdge: .minY)
        }
    }
    
    private func openInBrowser(_ urlString: String) {
        var finalURL = urlString
        if !urlString.hasPrefix("http://") && !urlString.hasPrefix("https://") {
            finalURL = "https://" + urlString
        }
        
        if let url = URL(string: finalURL) {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - Settings Window Delegate
class SettingsWindowDelegate: NSObject, NSWindowDelegate {
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        // Just close the window, don't terminate the app
        sender.orderOut(nil)
        return false // Don't actually close, just hide
    }
    
    func windowWillClose(_ notification: Notification) {
        // This prevents the window from actually closing and terminating the app
    }
}

// MARK: - Traditional Menu Bar View
struct MenuBarView: View {
    @EnvironmentObject var clipboardManager: ClipboardManager
    @StateObject private var appSettings = AppSettings()
    private static var settingsWindowDelegate = SettingsWindowDelegate()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Show only first 5 items
            let displayItems = Array(clipboardManager.items.prefix(5))
            
            if !displayItems.isEmpty {
                ForEach(displayItems) { item in
                    Button(action: {
                        clipboardManager.copyToClipboard(item)
                    }) {
                        HStack {
                            Image(systemName: item.typeIcon)
                                .foregroundColor(iconColor(for: item.type))
                                .frame(width: 16)
                            
                            Text(item.displayContent)
                                .lineLimit(nil) // Show full text
                                .multilineTextAlignment(.leading)
                                .truncationMode(.tail)
                                .frame(maxWidth: 300, alignment: .leading) // Ensure adequate width
                            
                            if item.isPinned {
                                Spacer()
                                Image(systemName: "pin.fill")
                                    .foregroundColor(.orange)
                                    .font(.caption)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                }
                
                if clipboardManager.items.count > 5 {
                    Divider()
                }
            }
            
            if clipboardManager.items.count > 5 {
                Button("Show All") {
                    clipboardManager.showWindow()
                    }
                    .buttonStyle(.plain)
            }
            
            if !clipboardManager.items.isEmpty {
                Divider()

                Button("Clear All") {
                clipboardManager.deleteAllItems()
            }
            .buttonStyle(.plain)
            }
            
            Divider()
            
            Button("Check for Updates...") {
                AppUpdateManager.shared.checkForUpdates()
                }
                .buttonStyle(.plain)
            
            Button("Settings...") {
                openSettingsWindow()
        }
        .buttonStyle(.plain)
                        
                        Divider()
                        
            Button("Quit Clipboard Manager") {
                NSApplication.shared.terminate(nil)
        }
        .buttonStyle(.plain)
        }
    }
    
    private func iconColor(for type: ClipboardItemType) -> Color {
        switch type {
        case .text:
            return .blue
        case .image:
            return .green
        case .url:
            return .purple
        }
    }
    
    private func openSettingsWindow() {
        if let window = NSApp.windows.first(where: { $0.title == "Clipboard Manager Settings" }) {
            window.makeKeyAndOrderFront(nil)
        } else {
            let settingsView = SettingsView().environmentObject(appSettings)
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            window.center()
            window.setFrameAutosaveName("Settings")
            window.contentView = NSHostingView(rootView: settingsView)
            window.title = "Clipboard Manager Settings"
            
            // Configure window to not affect app lifecycle
            window.isReleasedWhenClosed = false  // Keep the window in memory
            window.hidesOnDeactivate = false
            window.delegate = Self.settingsWindowDelegate  // Use custom delegate
            
            // Set window level to normal (not floating)
            window.level = .normal
            
            window.makeKeyAndOrderFront(nil)
        }
    }
}

// MARK: - Drag Area View for Window Dragging
struct DragAreaView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = DragView()
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
}

class DragView: NSView {
    override func mouseDown(with event: NSEvent) {
        window?.performDrag(with: event)
    }
}

// MARK: - Modern Settings View
struct SettingsView: View {
    @StateObject private var settings = AppSettings()
    
    var body: some View {
            TabView {
                GeneralSettingsView(settings: settings)
                    .tabItem {
                    Label("General", systemImage: "gear")
                    }
                
            UpdatesSettingsView(settings: settings)
                    .tabItem {
                    Label("Updates", systemImage: "arrow.down.circle")
                    }
            
            IntegrationsSettingsView()
                .tabItem {
                    Label("Integrations", systemImage: "link")
                }
            
            AboutSettingsView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
            }
        }
        .frame(width: 600, height: 480)
        .background(Color(NSColor.windowBackgroundColor))
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button("Done") {
                    // Close the window
                    NSApp.keyWindow?.performClose(nil)
                }
                .keyboardShortcut(.escape)
            }
        }
    }
}

// MARK: - General Settings Tab
struct GeneralSettingsView: View {
    @ObservedObject var settings: AppSettings
    
    var body: some View {
        ScrollView {
                VStack(spacing: 24) {
                    // Appearance Section
                VStack(alignment: .leading, spacing: 12) {
                            HStack {
                        Image(systemName: "paintbrush.fill")
                            .foregroundColor(.blue)
                            .font(.system(size: 16, weight: .medium))
                        Text("Appearance")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                            
                    VStack(spacing: 8) {
                        Picker("Theme", selection: $settings.appearanceMode) {
                                ForEach(AppearanceMode.allCases, id: \.self) { mode in
                                    Text(mode.displayName).tag(mode)
                                }
                            }
                            .pickerStyle(.segmented)
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Compact Mode")
                                    .font(.system(size: 14, weight: .medium))
                                Text("Smaller, minimal interface")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Toggle("", isOn: $settings.compactMode)
                                .toggleStyle(.switch)
                        }
                    }
                }
                .padding(20)
                .background(Color(NSColor.controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Notifications Section
                VStack(alignment: .leading, spacing: 12) {
                            HStack {
                        Image(systemName: "bell.fill")
                            .foregroundColor(.orange)
                            .font(.system(size: 16, weight: .medium))
                        Text("Notifications")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.primary)
                                Spacer()
                    }
                    
                    VStack(spacing: 16) {
                                HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Smart Notifications")
                                    .font(.system(size: 14, weight: .medium))
                                Text("Show notifications when items are copied")
                                    .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                            }
                                    Spacer()
                            Toggle("", isOn: $settings.showNotifications)
                                .toggleStyle(.switch)
                        }
                    }
                }
                .padding(20)
                .background(Color(NSColor.controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Performance Section
                VStack(alignment: .leading, spacing: 12) {
                            HStack {
                        Image(systemName: "speedometer")
                            .foregroundColor(.green)
                            .font(.system(size: 16, weight: .medium))
                        Text("Performance")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.primary)
                                Spacer()
                    }
                    
                    VStack(spacing: 16) {
                                HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Max Clipboard Items")
                                    .font(.system(size: 14, weight: .medium))
                                Text("Maximum number of items to store")
                                    .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                            }
                                    Spacer()
                            TextField("", value: $settings.maxItems, formatter: NumberFormatter())
                                .frame(width: 80)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Update Interval")
                                    .font(.system(size: 14, weight: .medium))
                                Text("How often to check clipboard (seconds)")
                                    .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            }
                            Spacer()
                            TextField("", value: $settings.updateInterval, formatter: NumberFormatter())
                                .frame(width: 80)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                }
                .padding(20)
                .background(Color(NSColor.controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                Spacer()
            }
            .padding(20)
        }
        .onDisappear {
                                        settings.saveSettings()
        }
    }
}

// MARK: - Updates Settings Tab
struct UpdatesSettingsView: View {
    @ObservedObject var settings: AppSettings
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Auto Updates Section
                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundColor(.orange)
                                            .font(.system(size: 16, weight: .medium))
                        Text("Automatic Updates")
                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(.primary)
                                        Spacer()
                    }
                    
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Check for Updates Automatically")
                                    .font(.system(size: 14, weight: .medium))
                                Text("Automatically check for new versions")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Toggle("", isOn: $settings.autoUpdateEnabled)
                                .toggleStyle(.switch)
                        }
                        
                        if settings.autoUpdateEnabled {
                            VStack(spacing: 16) {
                                        HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Install Updates Automatically")
                                            .font(.system(size: 14, weight: .medium))
                                        Text("Install updates without asking")
                                            .font(.system(size: 12))
                                                .foregroundColor(.secondary)
                                    }
                                            Spacer()
                                    Toggle("", isOn: $settings.autoInstallUpdates)
                                        .toggleStyle(.switch)
                                }
                                
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Check Interval")
                                            .font(.system(size: 14, weight: .medium))
                                        Text("How often to check for updates (hours)")
                                            .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    TextField("", value: $settings.checkUpdateInterval, formatter: NumberFormatter())
                                        .frame(width: 80)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                            }
                            .padding(.leading, 16)
                            .overlay(
                                Rectangle()
                                    .frame(width: 2)
                                    .foregroundColor(.orange.opacity(0.3)),
                                alignment: .leading
                            )
                        }
                    }
                }
                .padding(20)
                .background(Color(NSColor.controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                Spacer()
            }
            .padding(20)
        }
        .onDisappear {
            settings.saveSettings()
        }
    }
}

// MARK: - About Settings Tab
struct AboutSettingsView: View {
    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.1.6"
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // App Icon with modern styling
                VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 100, height: 100)
                    
                    Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
                            .resizable()
                            .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                }
            }
            
            // App Info with modern typography
            VStack(spacing: 12) {
                Text("Clipboard Manager")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                Text("Version \(appVersion)")
                    .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(Capsule())
            }
            
            // Description with better formatting
            VStack(spacing: 8) {
                Text("A simple and powerful clipboard manager for macOS")
                    .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                Text("Built with Swift and SwiftUI")
                    .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
            }
            .frame(maxWidth: 320)
            
            Spacer()
            
            // Footer with modern styling
            VStack(spacing: 8) {
                Text("clipboardgenius.app")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.blue)
                
                Text("© 2025 clipboardgenius.app")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 8)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(NSColor.controlBackgroundColor),
                    Color(NSColor.controlBackgroundColor).opacity(0.95)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

// MARK: - Integrations Settings Tab
struct IntegrationsSettingsView: View {
    @StateObject private var integrations = IntegrationManager()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "link.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.blue)
                        Text("Integrations")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    Text("Configure external service integrations")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                // Slack Integration
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "bubble.left.and.bubble.right.fill")
                                .foregroundColor(.purple)
                            Text("Slack Integration")
                                .font(.headline)
                            Spacer()
                        }
                        
                        Text("Enter your Slack webhook URL to send clipboard items to Slack channels.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField("Slack Webhook URL", text: $integrations.slackWebhookURL)
                            .textFieldStyle(.roundedBorder)
                            .help("Get webhook URL from Slack: Settings > Apps > Incoming Webhooks")
                    }
                    .padding()
                }
                
                // Discord Integration
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "message.fill")
                                .foregroundColor(.indigo)
                            Text("Discord Integration")
                                .font(.headline)
                            Spacer()
                        }
                        
                        Text("Enter your Discord webhook URL to send clipboard items to Discord channels.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField("Discord Webhook URL", text: $integrations.discordWebhookURL)
                            .textFieldStyle(.roundedBorder)
                            .help("Get webhook URL from Discord: Server Settings > Integrations > Webhooks")
                    }
                    .padding()
                }
                
                // Email Integration
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(.blue)
                            Text("Email Integration")
                                .font(.headline)
                            Spacer()
                        }
                        
                        Text("Choose your default email application for composing messages.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Picker("Default Email App", selection: $integrations.defaultEmailApp) {
                            ForEach(IntegrationManager.EmailApp.allCases, id: \.self) { app in
                                Text(app.rawValue).tag(app)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    .padding()
                }
                
                // Notes Integration
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "note.text")
                                .foregroundColor(.orange)
                            Text("Notes Integration")
                                .font(.headline)
                            Spacer()
                        }
                        
                        Text("Choose your default notes application for saving clipboard items.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Picker("Default Notes App", selection: $integrations.defaultNotesApp) {
                            ForEach(IntegrationManager.NotesApp.allCases, id: \.self) { app in
                                Text(app.rawValue).tag(app)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    .padding()
                }
                
                // Test Integration Section
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "testtube.2")
                                .foregroundColor(.green)
                            Text("Test Integrations")
                                .font(.headline)
                            Spacer()
                        }
                        
                        Text("Test your configured integrations with sample content.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 12) {
                            Button("Test Slack") {
                                integrations.shareToSlack("🧪 Test message from Clipboard Manager")
                            }
                            .disabled(integrations.slackWebhookURL.isEmpty)
                            
                            Button("Test Discord") {
                                integrations.shareToDiscord("🧪 Test message from Clipboard Manager")
                            }
                            .disabled(integrations.discordWebhookURL.isEmpty)
                            
                            Button("Test Email") {
                                integrations.composeEmail(with: "🧪 Test message from Clipboard Manager", subject: "Test from Clipboard Manager")
                            }
                            
                            Button("Test Notes") {
                                integrations.saveToNotes("🧪 Test message from Clipboard Manager", title: "Test Note")
                            }
                        }
                    }
                    .padding()
                }
                
                Spacer(minLength: 20)
            }
            .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - About View
struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
                        Image(systemName: "doc.on.clipboard.fill")
                .font(.system(size: 60))
                            .foregroundColor(.blue)
                    
            VStack {
                Text("Clipboard Manager")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("Version 1.1.0")
                            .foregroundColor(.secondary)
                    }
            
            Text("A simple and powerful clipboard manager for macOS.")
                        .multilineTextAlignment(.center)
                    
            Spacer()
            
            Text("© 2024 Your Name")
                        .foregroundColor(.secondary)
                }
        .padding()
        .frame(minWidth: 300, idealWidth: 350, minHeight: 200)
    }
}

// MARK: - Info Row
struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.secondary)
        }
    }
}

struct ModernSettingsSection<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    let content: Content
    
    init(title: String, icon: String, iconColor: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.iconColor = iconColor
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section Header
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(iconColor)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(iconColor.opacity(0.15))
                    )
                
                Text(title)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)
            
            // Content
            content
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [iconColor.opacity(0.3), iconColor.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let iconColor: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(iconColor)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(iconColor.opacity(0.15))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            content
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct ToggleRow: View {
    let title: String
    let description: String?
    @Binding var isOn: Bool
    
    init(title: String, description: String? = nil, isOn: Binding<Bool>) {
        self.title = title
        self.description = description
        self._isOn = isOn
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                if let description = description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
        }
    }
}

// MARK: - View Extension for Key Events
extension View {
    func onKeyDown(perform action: @escaping (NSEvent) -> Void) -> some View {
        self.background(KeyEventHandling(onKeyDown: action))
    }
}

struct KeyEventHandling: NSViewRepresentable {
    let onKeyDown: (NSEvent) -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = KeyView()
        view.onKeyDown = onKeyDown
        DispatchQueue.main.async {
            view.window?.makeFirstResponder(view)
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
}

class KeyView: NSView {
    var onKeyDown: ((NSEvent) -> Void)?
    
    override var acceptsFirstResponder: Bool { true }
    
    override func keyDown(with event: NSEvent) {
        onKeyDown?(event)
    }
}

// MARK: - Tip Row Component
struct TipRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.blue)
                .frame(width: 16)
            
            Text(text)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}

// MARK: - iCloud Sync Manager
class iCloudSyncManager: ObservableObject {
    private var container: CKContainer?
    private var database: CKDatabase?
    @Published var isSyncing = false
    @Published var syncEnabled = false
    
    init() {
        // Don't initialize CloudKit by default to prevent crashes
        // CloudKit requires proper entitlements and container setup
        syncEnabled = false
        print("iCloudSyncManager initialized - CloudKit disabled until proper entitlements are configured")
        // loadSyncSettings()
    }
    
    private func loadSyncSettings() {
        syncEnabled = UserDefaults.standard.bool(forKey: "iCloudSyncEnabled")
    }
    
    func toggleSync(_ enabled: Bool) {
        // CloudKit is disabled until proper entitlements are configured
        syncEnabled = false
        print("CloudKit sync is disabled - requires proper app entitlements and container setup")
    }
    
    private func checkiCloudStatus() {
        // CloudKit functionality disabled to prevent crashes
        print("iCloud status check disabled - requires proper CloudKit configuration")
    }
    
    private func setupCloudKitSubscription() {
        // CloudKit subscription disabled
        print("CloudKit subscription disabled - requires proper configuration")
    }
    
    func syncClipboardItem(_ item: ClipboardItem) {
        // CloudKit sync disabled to prevent crashes
        print("CloudKit sync disabled - item not synced: \(item.content.prefix(50))")
        return
    }
    
    func fetchRemoteItems(completion: @escaping ([ClipboardItem]) -> Void) {
        // CloudKit fetch disabled to prevent crashes
        print("CloudKit fetch disabled - returning empty array")
        completion([])
    }
}

// MARK: - Scheduled Clear Manager
class ScheduledClearManager: ObservableObject {
    private var isLoading = true // Prevent saving during initialization
    
    @Published var isEnabled: Bool = false {
        didSet { if !isLoading { saveSettings() } }
    }
    @Published var clearInterval: TimeInterval = 24 * 60 * 60 { // 24 hours default
        didSet { if !isLoading { saveSettings() } }
    }
    @Published var clearOnlyUnpinned: Bool = true {
        didSet { if !isLoading { saveSettings() } }
    }
    
    private var clearTimer: Timer?
    private weak var clipboardManager: ClipboardManager?
    
    enum ClearInterval: String, CaseIterable {
        case oneHour = "1 Hour"
        case sixHours = "6 Hours" 
        case twelveHours = "12 Hours"
        case oneDay = "1 Day"
        case threeDays = "3 Days"
        case oneWeek = "1 Week"
        
        var timeInterval: TimeInterval {
            switch self {
            case .oneHour: return 60 * 60
            case .sixHours: return 6 * 60 * 60
            case .twelveHours: return 12 * 60 * 60
            case .oneDay: return 24 * 60 * 60
            case .threeDays: return 3 * 24 * 60 * 60
            case .oneWeek: return 7 * 24 * 60 * 60
            }
        }
    }
    
    init(clipboardManager: ClipboardManager) {
        self.clipboardManager = clipboardManager
        loadSettings()
        setupTimer()
        isLoading = false // Enable auto-saving after initial load
    }
    
    private func loadSettings() {
        isEnabled = UserDefaults.standard.bool(forKey: "ScheduledClearEnabled")
        clearInterval = UserDefaults.standard.double(forKey: "ScheduledClearInterval")
        if clearInterval == 0 { clearInterval = 24 * 60 * 60 }
        clearOnlyUnpinned = UserDefaults.standard.bool(forKey: "ScheduledClearOnlyUnpinned")
    }
    
    func saveSettings() {
        UserDefaults.standard.set(isEnabled, forKey: "ScheduledClearEnabled")
        UserDefaults.standard.set(clearInterval, forKey: "ScheduledClearInterval")
        UserDefaults.standard.set(clearOnlyUnpinned, forKey: "ScheduledClearOnlyUnpinned")
        
        // Force synchronization to disk immediately
        UserDefaults.standard.synchronize()
        
        setupTimer()
    }
    
    private func setupTimer() {
        clearTimer?.invalidate()
        
        guard isEnabled else { return }
        
        clearTimer = Timer.scheduledTimer(withTimeInterval: clearInterval, repeats: true) { [weak self] _ in
            self?.performScheduledClear()
        }
    }
    
    private func performScheduledClear() {
        guard let clipboardManager = clipboardManager else { return }
        
        let cutoffDate = Date().addingTimeInterval(-clearInterval)
        
        if clearOnlyUnpinned {
            clipboardManager.items.removeAll { item in
                !item.isPinned && item.timestamp < cutoffDate
            }
        } else {
            clipboardManager.items.removeAll { item in
                item.timestamp < cutoffDate
            }
        }
        
        clipboardManager.saveItems()
        
        // Show notification
        let notification = NSUserNotification()
        notification.title = "Clipboard Cleared"
        notification.informativeText = "Old clipboard items have been automatically cleared"
        notification.soundName = nil
        NSUserNotificationCenter.default.deliver(notification)
    }
    
    func toggleScheduledClear(_ enabled: Bool) {
        isEnabled = enabled
        saveSettings()
    }
    
    func setClearInterval(_ interval: ClearInterval) {
        clearInterval = interval.timeInterval
        saveSettings()
    }
}

// MARK: - Integration Manager
class IntegrationManager: ObservableObject {
    private var isLoading = true // Prevent saving during initialization
    
    @Published var slackWebhookURL: String = "" {
        didSet { if !isLoading { saveSettings() } }
    }
    @Published var discordWebhookURL: String = "" {
        didSet { if !isLoading { saveSettings() } }
    }
    @Published var defaultEmailApp: EmailApp = .mail {
        didSet { if !isLoading { saveSettings() } }
    }
    @Published var defaultNotesApp: NotesApp = .notes {
        didSet { if !isLoading { saveSettings() } }
    }
    
    enum EmailApp: String, CaseIterable {
        case mail = "Mail"
        case outlook = "Microsoft Outlook"
        case gmail = "Gmail"
        case spark = "Spark"
        
        var bundleID: String {
            switch self {
            case .mail: return "com.apple.mail"
            case .outlook: return "com.microsoft.Outlook"
            case .gmail: return "com.google.Gmail"
            case .spark: return "com.readdle.smartemail-Mac"
            }
        }
    }
    
    enum NotesApp: String, CaseIterable {
        case notes = "Notes"
        case notion = "Notion"
        case obsidian = "Obsidian"
        case bear = "Bear"
        case devonthink = "DEVONthink"
        
        var bundleID: String {
            switch self {
            case .notes: return "com.apple.Notes"
            case .notion: return "notion.id"
            case .obsidian: return "md.obsidian"
            case .bear: return "net.shinyfrog.bear"
            case .devonthink: return "com.devon-technologies.think3"
            }
        }
        
        var urlScheme: String? {
            switch self {
            case .notes: return "notes://"
            case .notion: return "notion://"
            case .obsidian: return "obsidian://"
            case .bear: return "bear://"
            case .devonthink: return "x-devonthink://"
            }
        }
    }
    
    init() {
        loadSettings()
        isLoading = false // Enable auto-saving after initial load
    }
    
    private func loadSettings() {
        slackWebhookURL = UserDefaults.standard.string(forKey: "SlackWebhookURL") ?? ""
        discordWebhookURL = UserDefaults.standard.string(forKey: "DiscordWebhookURL") ?? ""
        if let emailAppString = UserDefaults.standard.string(forKey: "DefaultEmailApp"),
           let emailApp = EmailApp(rawValue: emailAppString) {
            defaultEmailApp = emailApp
        }
        if let notesAppString = UserDefaults.standard.string(forKey: "DefaultNotesApp"),
           let notesApp = NotesApp(rawValue: notesAppString) {
            defaultNotesApp = notesApp
        }
    }
    
    func saveSettings() {
        UserDefaults.standard.set(slackWebhookURL, forKey: "SlackWebhookURL")
        UserDefaults.standard.set(discordWebhookURL, forKey: "DiscordWebhookURL")
        UserDefaults.standard.set(defaultEmailApp.rawValue, forKey: "DefaultEmailApp")
        UserDefaults.standard.set(defaultNotesApp.rawValue, forKey: "DefaultNotesApp")
        
        // Force synchronization to disk immediately
        UserDefaults.standard.synchronize()
    }
    
    // MARK: - Slack Integration
    func shareToSlack(_ content: String, channel: String = "#general") {
        guard !slackWebhookURL.isEmpty, let url = URL(string: slackWebhookURL) else {
            showError("Slack webhook URL not configured")
            return
        }
        
        let payload = [
            "text": content,
            "channel": channel,
            "username": "Clipboard Manager",
            "icon_emoji": ":clipboard:"
        ]
        
        sendWebhookMessage(to: url, payload: payload, service: "Slack")
    }
    
    // MARK: - Discord Integration
    func shareToDiscord(_ content: String) {
        guard !discordWebhookURL.isEmpty, let url = URL(string: discordWebhookURL) else {
            showError("Discord webhook URL not configured")
            return
        }
        
        let payload = [
            "content": content,
            "username": "Clipboard Manager"
        ]
        
        sendWebhookMessage(to: url, payload: payload, service: "Discord")
    }
    
    private func sendWebhookMessage(to url: URL, payload: [String: Any], service: String) {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        } catch {
            showError("Failed to encode message for \(service)")
            return
        }
        
        URLSession.shared.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.showError("Failed to send to \(service): \(error.localizedDescription)")
                } else if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    self.showSuccess("Sent to \(service) successfully!")
                } else {
                    self.showError("Failed to send to \(service)")
                }
            }
        }.resume()
    }
    
    // MARK: - Email Integration
    func composeEmail(with content: String, subject: String = "Shared from Clipboard") {
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = content.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        switch defaultEmailApp {
        case .mail:
            let mailtoURL = "mailto:?subject=\(encodedSubject)&body=\(encodedBody)"
            if let url = URL(string: mailtoURL) {
                NSWorkspace.shared.open(url)
            }
        case .outlook, .gmail, .spark:
            // Try to open the specific app
            if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: defaultEmailApp.bundleID) {
                let mailtoURL = "mailto:?subject=\(encodedSubject)&body=\(encodedBody)"
                if let url = URL(string: mailtoURL) {
                    NSWorkspace.shared.open([url], withApplicationAt: appURL, configuration: NSWorkspace.OpenConfiguration()) { _, _ in }
                }
            } else {
                showError("\(defaultEmailApp.rawValue) is not installed")
            }
        }
    }
    
    // MARK: - Notes Integration
    func saveToNotes(_ content: String, title: String = "Clipboard Item") {
        let success: Bool
        
        switch defaultNotesApp {
        case .notes:
            // Use Notes URL scheme
            let encodedTitle = title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let encodedContent = content.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            if let url = URL(string: "notes://new?title=\(encodedTitle)&content=\(encodedContent)") {
                success = NSWorkspace.shared.open(url)
            } else {
                success = false
            }
        case .notion:
            // Open Notion with content in clipboard
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(content, forType: .string)
            if let url = URL(string: "notion://new") {
                success = NSWorkspace.shared.open(url)
            } else {
                success = false
            }
        case .obsidian:
            // Create new note in Obsidian
            let encodedTitle = title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let encodedContent = content.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            if let url = URL(string: "obsidian://new?name=\(encodedTitle)&content=\(encodedContent)") {
                success = NSWorkspace.shared.open(url)
            } else {
                success = false
            }
        case .bear:
            // Create new note in Bear
            let encodedTitle = title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let encodedContent = content.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            if let url = URL(string: "bear://x-callback-url/create?title=\(encodedTitle)&text=\(encodedContent)") {
                success = NSWorkspace.shared.open(url)
            } else {
                success = false
            }
        case .devonthink:
            // Create new document in DEVONthink
            let encodedTitle = title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let encodedContent = content.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            if let url = URL(string: "x-devonthink://createText?title=\(encodedTitle)&text=\(encodedContent)") {
                success = NSWorkspace.shared.open(url)
            } else {
                success = false
            }
        }
        
        // Show feedback to user
        if success {
            showSuccess("Opened \(defaultNotesApp.rawValue) successfully!")
        } else {
            showError("Failed to open \(defaultNotesApp.rawValue). Make sure it's installed.")
        }
    }
    
    private func showError(_ message: String) {
        let notification = NSUserNotification()
        notification.title = "Integration Error"
        notification.informativeText = message
        notification.soundName = NSUserNotificationDefaultSoundName
        NSUserNotificationCenter.default.deliver(notification)
    }
    
    private func showSuccess(_ message: String) {
        let notification = NSUserNotification()
        notification.title = "Success"
        notification.informativeText = message
        notification.soundName = nil
        NSUserNotificationCenter.default.deliver(notification)
    }
}