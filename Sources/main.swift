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
        if let customImage = loadSVGIcon() {
            Image(nsImage: customImage)
                .renderingMode(.template)
        } else {
            // Fallback to system icon
            Image(systemName: "doc.on.clipboard")
        }
    }
    
    private func loadSVGIcon() -> NSImage? {
        // Get the path to the SVG file
        let currentDirectory = FileManager.default.currentDirectoryPath
        let svgPath = "\(currentDirectory)/svgviewer-output.svg"
        
        guard let svgData = NSData(contentsOfFile: svgPath) else {
            print("Could not load SVG file at: \(svgPath)")
            return createFallbackIcon()
        }
        
        // Create NSImage from SVG data
        if let image = NSImage(data: svgData as Data) {
            // Resize to appropriate menu bar size
            let targetSize = NSSize(width: 18, height: 18)
            let resizedImage = NSImage(size: targetSize)
            
            resizedImage.lockFocus()
            image.draw(in: NSRect(origin: .zero, size: targetSize))
            resizedImage.unlockFocus()
            
            resizedImage.isTemplate = true
            return resizedImage
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
    @Published var updateInterval: Double = 0.5 // في الثواني
    @Published var autoUpdateEnabled: Bool = true
    @Published var checkUpdateInterval: Int = 24 // في الساعات
    
    init() {
        loadSettings()
        applyAppearanceMode()
    }
    
    private func loadSettings() {
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
        
        let savedCheckInterval = UserDefaults.standard.integer(forKey: "CheckUpdateInterval")
        if savedCheckInterval > 0 {
            self.checkUpdateInterval = savedCheckInterval
        }
    }
    
    func saveSettings() {
        UserDefaults.standard.set(appearanceMode.rawValue, forKey: "AppearanceMode")
        UserDefaults.standard.set(maxItems, forKey: "MaxItems")
        UserDefaults.standard.set(updateInterval, forKey: "UpdateInterval")
        UserDefaults.standard.set(autoUpdateEnabled, forKey: "AutoUpdateEnabled")
        UserDefaults.standard.set(checkUpdateInterval, forKey: "CheckUpdateInterval")
        applyAppearanceMode()
        
        // إعادة تشغيل المراقبة بالفترة الجديدة
        ClipboardManager.shared.restartMonitoring()
        
        // إعادة تشغيل فحص التحديثات
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
    private let currentVersion = "1.0.0"
    private let updateCheckURL = "https://api.github.com/repos/your-username/clipboard-manager/releases/latest"
    
    private init() {}
    
    func startPeriodicCheck() {
        stopPeriodicCheck()
        let interval = TimeInterval(AppSettings().checkUpdateInterval * 3600) // تحويل الساعات إلى ثواني
        updateTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            self.checkForUpdates()
        }
        // فحص فوري عند البدء
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
                
                // مقارنة الإصدارات
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
        notification.title = "تحديث جديد متاح"
        notification.informativeText = "إصدار \(latestVersion) من مدير الحافظة متاح الآن"
        notification.soundName = NSUserNotificationDefaultSoundName
        notification.hasActionButton = true
        notification.actionButtonTitle = "تحديث"
        notification.otherButtonTitle = "لاحقاً"
        
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
        let downloadsPath = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
        let destinationURL = downloadsPath.appendingPathComponent("ClipboardManager-\(latestVersion).app")
        
        do {
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            try FileManager.default.moveItem(at: url, to: destinationURL)
            
            // فتح مجلد التنزيلات لإظهار التطبيق الجديد
            NSWorkspace.shared.selectFile(destinationURL.path, inFileViewerRootedAtPath: downloadsPath.path)
            
            // إظهار رسالة للمستخدم
            let alert = NSAlert()
            alert.messageText = "تم تنزيل التحديث بنجاح"
            alert.informativeText = "تم حفظ الإصدار الجديد في مجلد التنزيلات. يرجى إغلاق التطبيق الحالي وفتح الإصدار الجديد."
            alert.addButton(withTitle: "موافق")
            alert.runModal()
            
        } catch {
            print("خطأ في تثبيت التحديث: \(error)")
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
        // إيقاف المراقبة الحالية
        timer?.invalidate()
        timer = nil
        
        // بدء المراقبة بالفترة الجديدة
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


// MARK: - Menu Bar View (Enhanced)
// This part is for the menu bar icon's dropdown, not the main popup window.
struct MenuBarView: View {
    @EnvironmentObject var clipboardManager: ClipboardManager
    @StateObject private var updateManager = AppUpdateManager.shared
    @State private var searchText = ""
    @State private var showingMore = false
    
    var filteredItems: [ClipboardItem] {
        if searchText.isEmpty {
            return clipboardManager.items
        } else {
            return clipboardManager.items.filter { $0.content.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Clean Header
            HStack {
                Text("Clipboard")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    clipboardManager.showingSettings = true
                }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.borderless)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(NSColor.controlBackgroundColor))
            
            // Search Bar
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                TextField("Search clipboard...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.1))
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
            
            Divider()
            
            // Content Area
            if filteredItems.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "clipboard")
                        .font(.system(size: 48, weight: .light))
                        .foregroundColor(.secondary.opacity(0.6))
                    
                    Text("No clipboard items")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Text("Copy text to see it here")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(filteredItems.prefix(showingMore ? filteredItems.count : 8).enumerated()), id: \.element.id) { index, item in
                            MenuBarItemView(item: item)
                                .background(
                                    Rectangle()
                                        .fill(index % 2 == 0 ? Color.clear : Color.gray.opacity(0.05))
                                )
                        }
                    }
                }
                .frame(maxHeight: 400)
                
                if filteredItems.count > 8 && !showingMore {
                    Divider()
                    
                    Button(action: {
                        showingMore = true
                    }) {
                        HStack {
                            Text("Show \(filteredItems.count - 8) more items")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.blue)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.down")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.blue)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.blue.opacity(0.05))
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // Update Section
            if updateManager.isUpdateAvailable || updateManager.isChecking {
                Divider()
                
                VStack(spacing: 8) {
                    if updateManager.isChecking {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Checking for updates...")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                    } else if updateManager.isUpdateAvailable {
                        HStack {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.blue)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Update Available")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.primary)
                                Text("Version \(updateManager.latestVersion)")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button("Download") {
                                updateManager.downloadAndInstallUpdate()
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.blue.opacity(0.05))
                    }
                }
            }
            
            // Footer with update check button
            Divider()
            
            HStack {
                Button(action: {
                    updateManager.checkForUpdates()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 11))
                        Text("Check Updates")
                            .font(.system(size: 11))
                    }
                    .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .disabled(updateManager.isChecking)
                
                Spacer()
                
                Text("v1.0.0")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.tertiary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        }
        .frame(width: 400)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .preferredColorScheme(nil)
        .sheet(isPresented: $clipboardManager.showingSettings) {
            SettingsView()
        }
    }
}

// MARK: - Menu Bar Item View
struct MenuBarItemView: View {
    let item: ClipboardItem
    @EnvironmentObject var clipboardManager: ClipboardManager
    @State private var isHovered = false
    
    var body: some View {
        Button(action: {
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(item.content, forType: .string)
        }) {
            HStack(spacing: 12) {
                // Content Text
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.content)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                    
                    Text("Just now")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Action Buttons (shown on hover)
                if isHovered {
                    HStack(spacing: 8) {
                        Button(action: {
                            clipboardManager.togglePin(for: item)
                        }) {
                            Image(systemName: item.isPinned ? "pin.fill" : "pin")
                                .font(.system(size: 12))
                                .foregroundColor(item.isPinned ? .orange : .secondary)
                        }
                        .buttonStyle(.plain)
                        .help(item.isPinned ? "Unpin" : "Pin")
                        
                        Menu {
                            Button("Copy") {
                                let pasteboard = NSPasteboard.general
                                pasteboard.clearContents()
                                pasteboard.setString(item.content, forType: .string)
                            }
                            
                            Button("Share") {
                                shareToOtherApps(item.content)
                            }
                            
                            Divider()
                            
                            Button("Delete") {
                                clipboardManager.removeItem(item)
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        .menuStyle(.borderlessButton)
                        .help("More Options")
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .help("Click to copy")
    }
    

    
    private var contentTypeIcon: String {
        if isURL(item.content) {
            return "link"
        } else if item.content.contains("@") && item.content.contains(".") {
            return "envelope"
        } else if item.content.allSatisfy({ $0.isNumber || $0.isWhitespace || "+-().".contains($0) }) {
            return "phone"
        } else {
            return "doc.text"
        }
    }
    
    private var contentTypeColor: Color {
        if isURL(item.content) {
            return .blue
        } else if item.content.contains("@") && item.content.contains(".") {
            return .green
        } else if item.content.allSatisfy({ $0.isNumber || $0.isWhitespace || "+-().".contains($0) }) {
            return .purple
        } else {
            return .gray
        }
    }
    
    private func isURL(_ string: String) -> Bool {
        return string.hasPrefix("http://") || string.hasPrefix("https://") || string.hasPrefix("www.")
    }
    
    private func openInBrowser(_ url: String) {
        var urlString = url
        if !urlString.hasPrefix("http://") && !urlString.hasPrefix("https://") {
            urlString = "https://" + urlString
        }
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func shareToOtherApps(_ content: String) {
        let sharingService = NSSharingService(named: .sendViaAirDrop)
        sharingService?.perform(withItems: [content])
    }
    
    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
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

// MARK: - Settings View
struct SettingsView: View {
    @StateObject private var settings = AppSettings()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Modern Header with gradient
            VStack(spacing: 0) {
                HStack {
                    HStack(spacing: 12) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text("Settings")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        settings.saveSettings()
                        dismiss()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16, weight: .medium))
                            Text("Done")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(
                                colors: [.blue, .blue.opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .cornerRadius(12)
                        .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(.plain)
                    .scaleEffect(1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: false)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                
                // Subtle separator
                Rectangle()
                    .fill(LinearGradient(
                        colors: [.gray.opacity(0.3), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .frame(height: 1)
            }
            .background(
                LinearGradient(
                    colors: [Color(NSColor.controlBackgroundColor), Color(NSColor.controlBackgroundColor).opacity(0.95)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            
            // Tabbed Content
            TabView {
                GeneralSettingsView(settings: settings)
                    .tabItem {
                        Image(systemName: "gearshape")
                        Text("General")
                    }
                
                AboutView()
                    .tabItem {
                        Image(systemName: "info.circle")
                        Text("About")
                    }
            }
            .padding(.top, 20)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(width: 600, height: 500)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - General Settings View
struct GeneralSettingsView: View {
    @ObservedObject var settings: AppSettings
    
    var body: some View {
        // Settings Content with modern design
        ScrollView {
                VStack(spacing: 24) {
                    // Appearance Section
                    ModernSettingsSection(
                        title: "Appearance",
                        icon: "paintbrush.fill",
                        iconColor: .orange
                    ) {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "sun.max.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.orange)
                                Text("Theme")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                            
                            Picker("Appearance", selection: $settings.appearanceMode) {
                                ForEach(AppearanceMode.allCases, id: \.self) { mode in
                                    Text(mode.displayName).tag(mode)
                                }
                            }
                            .pickerStyle(.segmented)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                            .onChange(of: settings.appearanceMode) { _ in
                                settings.saveSettings()
                            }
                        }
                    }
                    
                    // Storage Section
                    ModernSettingsSection(
                        title: "Storage",
                        icon: "internaldrive.fill",
                        iconColor: .green
                    ) {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "tray.full.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.green)
                                Text("Maximum Items")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.primary)
                                Spacer()
                                
                                Text("\(settings.maxItems)")
                                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(LinearGradient(
                                                colors: [.green, .green.opacity(0.8)],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            ))
                                    )
                                    .shadow(color: .green.opacity(0.3), radius: 4, x: 0, y: 2)
                            }
                            
                            VStack(spacing: 8) {
                                Slider(value: Binding(
                                    get: { Double(settings.maxItems) },
                                    set: { settings.maxItems = Int($0) }
                                ), in: 10...500, step: 10)
                                .accentColor(.green)
                                .onChange(of: settings.maxItems) { _ in
                                    settings.saveSettings()
                                }
                                
                                HStack {
                                    Text("10")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("500")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    
                    // Auto-Update Section
                    ModernSettingsSection(
                        title: "Auto-Update",
                        icon: "arrow.clockwise.circle.fill",
                        iconColor: .blue
                    ) {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "timer")
                                    .font(.system(size: 18))
                                    .foregroundColor(.blue)
                                Text("Update Interval")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.primary)
                                Spacer()
                                
                                Text(String(format: "%.1f s", settings.updateInterval))
                                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(LinearGradient(
                                                colors: [.blue, .blue.opacity(0.8)],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            ))
                                    )
                                    .shadow(color: .blue.opacity(0.3), radius: 4, x: 0, y: 2)
                            }
                            
                            VStack(spacing: 8) {
                                Slider(value: $settings.updateInterval, in: 0.1...5.0, step: 0.1)
                                    .accentColor(.blue)
                                    .onChange(of: settings.updateInterval) { _ in
                                        settings.saveSettings()
                                    }
                                
                                HStack {
                                    Text("0.1s (Fast)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("5.0s (Slow)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Text("Controls how often the app checks for clipboard changes. Lower values provide faster detection but use more system resources.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
                        }
                    }
                    
                    // App Updates Section
                    ModernSettingsSection(
                        title: "App Updates",
                        icon: "arrow.down.circle.fill",
                        iconColor: .indigo
                    ) {
                        VStack(alignment: .leading, spacing: 16) {
                            Toggle(isOn: $settings.autoUpdateEnabled) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(settings.autoUpdateEnabled ? .green : .gray)
                                    Text("Enable Automatic Updates")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.primary)
                                }
                            }
                            .toggleStyle(SwitchToggleStyle(tint: .indigo))
                            .onChange(of: settings.autoUpdateEnabled) { _ in
                                settings.saveSettings()
                            }
                            
                            if settings.autoUpdateEnabled {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Image(systemName: "clock.fill")
                                            .font(.system(size: 16))
                                            .foregroundColor(.indigo)
                                        Text("Check Interval")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.primary)
                                        Spacer()
                                        
                                        Text(String(format: "%.0f hours", settings.checkUpdateInterval))
                                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 4)
                                            .background(
                                                Capsule()
                                                    .fill(LinearGradient(
                                                        colors: [.indigo, .indigo.opacity(0.8)],
                                                        startPoint: .top,
                                                        endPoint: .bottom
                                                    ))
                                            )
                                            .shadow(color: .indigo.opacity(0.3), radius: 3, x: 0, y: 1)
                                    }
                                    
                                    VStack(spacing: 6) {
                                        Slider(value: $settings.checkUpdateInterval, in: 1...168, step: 1)
                                            .accentColor(.indigo)
                                            .onChange(of: settings.checkUpdateInterval) { _ in
                                                settings.saveSettings()
                                            }
                                        
                                        HStack {
                                            Text("1 hour")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            Spacer()
                                            Text("1 week")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    
                                    Text("The app will automatically check for updates from GitHub and notify you when a new version is available.")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.top, 4)
                                }
                                .padding(.leading, 8)
                            }
                        }
                    }
                    
                    // Additional Features Section
                    ModernSettingsSection(
                        title: "Features",
                        icon: "star.fill",
                        iconColor: .purple
                    ) {
                        VStack(spacing: 16) {
                            FeatureRow(
                                icon: "keyboard.fill",
                                title: "Keyboard Shortcuts",
                                description: "⌘+Shift+V to open clipboard",
                                iconColor: .blue
                            )
                            
                            Divider()
                                .background(Color.gray.opacity(0.3))
                            
                            FeatureRow(
                                icon: "pin.fill",
                                title: "Pin Items",
                                description: "Keep important items at the top",
                                iconColor: .orange
                            )
                            
                            Divider()
                                .background(Color.gray.opacity(0.3))
                            
                            FeatureRow(
                                icon: "magnifyingglass",
                                title: "Search",
                                description: "Quickly find your clipboard items",
                                iconColor: .green
                            )
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
            }
            .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - About View
struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // App Icon and Title
                VStack(spacing: 16) {
                    if let logoImage = NSImage(named: "logo.png") {
                        Image(nsImage: logoImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 80)
                            .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                    } else {
                        Image(systemName: "doc.on.clipboard.fill")
                            .font(.system(size: 80, weight: .light))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    
                    VStack(spacing: 8) {
                        Text("ClipboardGenius")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text("Version 1.0.0")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                
                // Description
                VStack(spacing: 16) {
                    Text("A powerful clipboard manager for macOS")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    Text("Keep track of your clipboard history, search through items, and access them quickly with keyboard shortcuts. Built with SwiftUI for a modern and intuitive experience.")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .padding(.horizontal, 20)
                }
                
                // Features
                ModernSettingsSection(
                    title: "Features",
                    icon: "star.fill",
                    iconColor: .orange
                ) {
                    VStack(spacing: 12) {
                        FeatureRow(
                            icon: "keyboard.fill",
                            title: "Global Hotkey",
                            description: "Quick access with ⌘+X",
                            iconColor: .blue
                        )
                        
                        Divider()
                        
                        FeatureRow(
                            icon: "magnifyingglass",
                            title: "Smart Search",
                            description: "Find clipboard items instantly",
                            iconColor: .green
                        )
                        
                        Divider()
                        
                        FeatureRow(
                            icon: "paintbrush.fill",
                            title: "Theme Support",
                            description: "Light, dark, and system themes",
                            iconColor: .purple
                        )
                        
                        Divider()
                        
                        FeatureRow(
                            icon: "internaldrive.fill",
                            title: "Configurable Storage",
                            description: "Customize maximum items (10-500)",
                            iconColor: .orange
                        )
                    }
                }
                
                // System Info
                ModernSettingsSection(
                    title: "System Information",
                    icon: "info.circle.fill",
                    iconColor: .blue
                ) {
                    VStack(spacing: 12) {
                        InfoRow(title: "Platform", value: "macOS")
                        Divider()
                        InfoRow(title: "Framework", value: "SwiftUI")
                        Divider()
                        InfoRow(title: "Language", value: "Swift")
                        Divider()
                        InfoRow(title: "Build", value: "Release")
                    }
                }
                
                // Contact & Links
                ModernSettingsSection(
                    title: "Contact & Links",
                    icon: "link.circle.fill",
                    iconColor: .green
                ) {
                    VStack(spacing: 12) {
                        InfoRow(title: "Website", value: "clipboardgenius.app")
                        Divider()
                        InfoRow(title: "Email", value: "contact@clipboardgenius.app")
                    }
                }
                
                // Copyright
                VStack(spacing: 8) {
                    Text("© 2025 ClipboardGenius")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Text("Created by Salim Moustanir")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Text("github.com/salimmous")
                        .font(.system(size: 11, weight: .regular, design: .monospaced))
                        .foregroundColor(.blue)
                    
                    Text("Made with ❤️ for productivity")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
        }
        .background(Color(NSColor.windowBackgroundColor))
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
                    .foregroundStyle(
                        LinearGradient(
                            colors: [iconColor, iconColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
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