import SwiftUI
import AppKit
import Combine
import Carbon

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
            "/Users/salim/Downloads/copy clipboard /logos/Assets.xcassets/AppIcon.appiconset/32.png",
            "/Users/salim/Downloads/copy clipboard /logos/Assets.xcassets/AppIcon.appiconset/16.png",
            "/Users/salim/Downloads/copy clipboard /clipboard-logo.png"
        ]
        
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
    
    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
}

class AppSettings: ObservableObject {
    @Published var appearanceMode: AppearanceMode = .system
    @Published var maxItems: Int = 100
    @Published var updateInterval: Double = 0.5 // in seconds
    @Published var autoUpdateEnabled: Bool = true
    @Published var checkUpdateInterval: Double = 24.0 // in hours
    @Published var autoInstallUpdates: Bool = false // auto-install updates
    
    init() {
        loadSettings()
        applyAppearanceMode()
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
        UserDefaults.standard.set(checkUpdateInterval, forKey: "CheckUpdateInterval")
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
            case .light:
                NSApp.appearance = NSAppearance(named: .aqua)
            case .dark:
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
    private let currentVersion = "1.1.5"
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
struct ClipboardItem: Identifiable, Codable, Hashable {
    let id: UUID
    let content: String
    var isPinned: Bool
    
    // Simplified init
    init(content: String, isPinned: Bool = false) {
        self.id = UUID()
        self.content = content
        self.isPinned = isPinned
    }
}



// MARK: - Clipboard Manager
class ClipboardManager: ObservableObject {
    static let shared = ClipboardManager()
    
    @Published var items: [ClipboardItem] = []
    @Published var isWindowVisible = false
    @Published var showingSettings = false
    
    private var timer: Timer?
    private var lastChangeCount: Int = 0
    private var clipboardWindow: NSWindow?
    private let settings = AppSettings()
    
    var maxItems: Int {
        return settings.maxItems
    }
    
    private init() {
        loadItems()
    }
    
    func startMonitoring() {
        lastChangeCount = NSPasteboard.general.changeCount
        timer = Timer.scheduledTimer(withTimeInterval: settings.updateInterval, repeats: true) { _ in
            self.checkClipboard()
        }
    }
    
    func restartMonitoring() {
        // Stop current monitoring
        timer?.invalidate()
        timer = nil
        
        // Start monitoring with new interval
        startMonitoring()
    }
    
    private func checkClipboard() {
        if NSPasteboard.general.changeCount != lastChangeCount {
            lastChangeCount = NSPasteboard.general.changeCount
            if let string = NSPasteboard.general.string(forType: .string), !string.isEmpty {
                addItem(content: string)
            }
        }
    }
    
    func addItem(content: String) {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        items.removeAll { $0.content == trimmedContent }
        items.insert(ClipboardItem(content: trimmedContent), at: 0)
        
        if items.count > maxItems {
            items = Array(items.prefix(maxItems))
        }
        sortItems()
        saveItems()
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
        pasteboard.setString(item.content, forType: .string)
        lastChangeCount = pasteboard.changeCount
    }
    
    func removeItem(_ item: ClipboardItem) {
        items.removeAll { $0.id == item.id }
        saveItems()
    }
    
    func saveItems() {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: "ClipboardItems")
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
        if clipboardWindow == nil {
            let contentView = ClipboardPopupView().environmentObject(self)
            clipboardWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 380, height: 450),
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            clipboardWindow?.contentView = NSHostingView(rootView: contentView)
            clipboardWindow?.backgroundColor = .clear
            clipboardWindow?.isOpaque = false
            clipboardWindow?.hasShadow = true
            clipboardWindow?.level = .floating
            clipboardWindow?.isMovableByWindowBackground = true
            clipboardWindow?.center()
            
            // Enable dragging
            if let contentView = clipboardWindow?.contentView {
                contentView.wantsLayer = true
            }
        }
        clipboardWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        isWindowVisible = true
    }
    
    func hideWindow() {
        clipboardWindow?.orderOut(nil)
        isWindowVisible = false
    }
}

// MARK: - Clipboard Popup View (MODERN DESIGN)
struct ClipboardPopupView: View {
    @EnvironmentObject var clipboardManager: ClipboardManager
    @State private var selectedIndex: Int? = 0
    @State private var searchText = ""
    
    var filteredItems: [ClipboardItem] {
        if searchText.isEmpty {
            return clipboardManager.items
        } else {
            return clipboardManager.items.filter { $0.content.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with title, clear button, and close button (Draggable area)
            HStack {
                Text("Clipboard")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("Clear all") {
                    clipboardManager.items.removeAll()
                    clipboardManager.saveItems()
                }
                .font(.system(size: 14))
                .foregroundColor(.blue)
                
                Button(action: {
                    clipboardManager.showingSettings = true
                }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .padding(.leading, 8)
                
                Button(action: {
                    clipboardManager.hideWindow()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .padding(.leading, 8)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)
            .background(DragAreaView())
            
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search clipboard...", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(NSColor.textBackgroundColor).opacity(0.5))
            .cornerRadius(8)
            .padding(.horizontal, 16)
            .padding(.bottom, 12)

            // Items List
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(Array(filteredItems.enumerated()), id: \.element.id) { index, item in
                        ClipboardPopupItemView(
                            item: item,
                            isSelected: selectedIndex == index
                        )
                        .onTapGesture {
                            selectedIndex = index
                            clipboardManager.copyToClipboard(item)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                clipboardManager.hideWindow()
                            }
                        }
                        .onHover { hovering in
                            if hovering {
                                selectedIndex = index
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 8)
        )
        .preferredColorScheme(nil) // Adapts to system appearance
        .sheet(isPresented: $clipboardManager.showingSettings) {
            SettingsView()
        }
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
    
    private func handleKeyDown(_ event: NSEvent) {
        let items = clipboardManager.items
        guard !items.isEmpty else { return }
        
        switch event.keyCode {
        case 36: // Enter
            if let index = selectedIndex, index < items.count {
                clipboardManager.copyToClipboard(items[index])
                clipboardManager.hideWindow()
            }
        case 53: // Escape
            clipboardManager.hideWindow()
        default:
            break
        }
    }
}

// MARK: - Clipboard Popup Item View (MODERN DESIGN)
struct ClipboardPopupItemView: View {
    let item: ClipboardItem
    let isSelected: Bool
    @EnvironmentObject var clipboardManager: ClipboardManager
    
    var body: some View {
        HStack(spacing: 12) {
            // Pin indicator
            if item.isPinned {
                Image(systemName: "pin.fill")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.orange)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(item.content)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text(item.isPinned ? "Pinned" : "Just now")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 4) {
                Menu {
                    Button("Share to WhatsApp") {
                        shareToWhatsApp(item.content)
                    }
                    
                    Button("Share to Other Apps") {
                        shareToOtherApps(item.content)
                    }
                    
                    if isURL(item.content) {
                        Button("Open in Browser") {
                            openInBrowser(item.content)
                        }
                    }
                    
                    Divider()
                    
                    Button("Copy") {
                                 let pasteboard = NSPasteboard.general
                                 pasteboard.clearContents()
                                 pasteboard.setString(item.content, forType: .string)
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
    
    private func shareToWhatsApp(_ text: String) {
        let encodedText = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let whatsappURL = "whatsapp://send?text=\(encodedText)"
        
        if let url = URL(string: whatsappURL) {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func shareToOtherApps(_ text: String) {
        let sharingPicker = NSSharingServicePicker(items: [text])
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
    
    private func isURL(_ string: String) -> Bool {
        let urlPattern = "^(https?://)|(www\\.)|(\\w+\\.(com|org|net|edu|gov|mil|int|co|uk|de|fr|jp|cn|au|ca|br|in|ru|it|es|nl|se|no|dk|fi|pl|be|ch|at|cz|hu|pt|gr|tr|il|za|mx|ar|cl|pe|ve|uy|py|bo|ec|co|cr|pa|gt|hn|sv|ni|cu|do|ht|jm|tt|bb|gd|lc|vc|ag|kn|dm|bs|bz|gy|sr|fk|gl|fo|is|ie|mt|cy|lu|li|ad|mc|sm|va|si|sk|hr|ba|mk|al|bg|ro|md|ua|by|lt|lv|ee|fi|se|no|dk|is|ie|gb|fr|es|pt|it|ch|at|de|nl|be|lu|pl|cz|sk|hu|si|hr|ba|rs|me|mk|al|bg|ro|md|ua|by|lt|lv|ee)).*$"
        
        return string.range(of: urlPattern, options: .regularExpression) != nil
    }
}


// MARK: - Traditional Menu Bar View
struct MenuBarView: View {
    @EnvironmentObject var clipboardManager: ClipboardManager
    @StateObject private var appSettings = AppSettings()
    @StateObject private var updateManager = AppUpdateManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Pinned Items
            ForEach(clipboardManager.items.filter { $0.isPinned }) { item in
                    Button(action: {
                    clipboardManager.copyToClipboard(item)
                }) {
                    HStack {
                        Text(item.content)
                            .lineLimit(1)
                        Spacer()
                        Image(systemName: "pin.fill")
                                .foregroundColor(.secondary)
                        }
                    }
            }
            
            if !clipboardManager.items.filter({ $0.isPinned }).isEmpty {
                Divider()
            }
            
            // Recent Items
            ForEach(clipboardManager.items.filter { !$0.isPinned }.prefix(10)) { item in
                    Button(action: {
                    clipboardManager.copyToClipboard(item)
                }) {
                    Text(item.content)
                        .lineLimit(1)
                }
            }
            
            if clipboardManager.items.isEmpty {
                Text("No clipboard items")
                            .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
            }
            
            Divider()
            
            // Main Actions
            Button("Show All") {
                clipboardManager.showWindow()
                    }
            
            Button("Clear All") {
                clipboardManager.deleteAllItems()
            }
            
            Divider()
            
            // Settings and Updates
            Button("Check for Updates...") {
                    updateManager.checkForUpdates()
            }
            
            Button("Settings...") {
                openSettingsWindow()
                    }
            
            Divider()
            
            // Quit
            Button("Quit Clipboard Manager") {
                NSApplication.shared.terminate(nil)
                }
            }
        .padding(6)
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
            window.isReleasedWhenClosed = true
            window.hidesOnDeactivate = false
            
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
            
            AboutSettingsView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 600, height: 400)
        .background(Color(NSColor.windowBackgroundColor))
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
                
                Text("Version 1.1.3")
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