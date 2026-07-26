import SwiftUI
import AppKit
import Combine
import Carbon
import UserNotifications

// MARK: - Main App Entry Point
@main
struct ClipboardManagerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environmentObject(ClipboardManager.shared)
        } label: {
            CustomClipboardIcon()
        }
    }
}

// MARK: - App Delegate
class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
        UNUserNotificationCenter.current().delegate = self
        
        let updateAction = UNNotificationAction(identifier: "UPDATE_NOW", title: "Update Now", options: .foreground)
        let laterAction = UNNotificationAction(identifier: "LATER", title: "Later", options: [])
        let updateCategory = UNNotificationCategory(identifier: "UPDATE_CATEGORY", actions: [updateAction, laterAction], intentIdentifiers: [], options: [])
        UNUserNotificationCenter.current().setNotificationCategories([updateCategory])
        
        registerGlobalHotkey()
        
        _ = ClipboardManager.shared
        _ = AppUpdateManager.shared
        
        let settings = AppSettings()
        if settings.autoUpdateEnabled {
            AppUpdateManager.shared.startPeriodicCheck()
        }
        
        checkFirstRunAndShowWelcome()
        NSApp.setActivationPolicy(.accessory)
    }
    
    private func checkFirstRunAndShowWelcome() {
        let lastVersion = UserDefaults.standard.string(forKey: "LastRunVersion")
        let currentVersion = "1.2.0"
        
        if lastVersion != currentVersion {
            UserDefaults.standard.set(currentVersion, forKey: "LastRunVersion")
            if lastVersion == nil {
                scheduleWelcomeNotifications()
            }
        }
    }
    
    private func scheduleWelcomeNotifications() {
        let welcome = UNMutableNotificationContent()
        welcome.title = "👋 Welcome to ClipboardManager v1.2!"
        welcome.body = "Press ⌘X anytime. OCR Text Search & Password Manager Exclusion enabled."
        welcome.sound = .default
        let welcomeRequest = UNNotificationRequest(identifier: "Welcome", content: welcome, trigger: UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false))
        UNUserNotificationCenter.current().add(welcomeRequest)
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        unregisterGlobalHotkey()
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if response.notification.request.identifier == "UpdateAvailable" {
            if response.actionIdentifier == "UPDATE_NOW" || response.actionIdentifier == UNNotificationDefaultActionIdentifier {
                DispatchQueue.main.async {
                    AppUpdateManager.shared.downloadAndInstallUpdate()
                }
            }
        }
        completionHandler()
    }
    
    private func registerGlobalHotkey() {
        let hotKeyID = EventHotKeyID(signature: "CBMG".fourCharCodeValue, id: 1)
        let keyCode: UInt32 = 7 // 'X' key
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

// MARK: - Custom Window for Key Handling
class ClipboardWindow: NSWindow {
    var clipboardManager: ClipboardManager?
    
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // Escape
            clipboardManager?.hideWindow()
            return
        }
        if event.keyCode == 36 { // Enter
            super.keyDown(with: event)
            return
        }
        super.keyDown(with: event)
    }
    
    override var canBecomeKey: Bool { true }
    override var acceptsFirstResponder: Bool { true }
}

// MARK: - Settings Window Delegate
class SettingsWindowDelegate: NSObject, NSWindowDelegate {
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.orderOut(nil)
        return false
    }
}

// MARK: - Menu Bar View
struct MenuBarView: View {
    @EnvironmentObject var clipboardManager: ClipboardManager
    @StateObject private var appSettings = AppSettings()
    private static var settingsWindowDelegate = SettingsWindowDelegate()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
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
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .frame(maxWidth: 300, alignment: .leading)
                            
                            if item.isPinned {
                                Spacer()
                                Image(systemName: "pin.fill")
                                    .foregroundColor(.orange)
                                    .font(.caption)
                            }
                        }
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
        case .text: return .blue
        case .image: return .green
        case .url: return .purple
        }
    }
    
    private func openSettingsWindow() {
        if let window = NSApp.windows.first(where: { $0.title == "Clipboard Manager Settings" }) {
            window.makeKeyAndOrderFront(nil)
        } else {
            let settingsView = SettingsView().environmentObject(appSettings)
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 650, height: 450),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            window.center()
            window.contentView = NSHostingView(rootView: settingsView)
            window.title = "Clipboard Manager Settings"
            window.isReleasedWhenClosed = false
            window.delegate = Self.settingsWindowDelegate
            window.makeKeyAndOrderFront(nil)
        }
    }
}

// MARK: - Custom Clipboard Icon
struct CustomClipboardIcon: View {
    var body: some View {
        Image(systemName: "doc.on.clipboard")
    }
}

// MARK: - Drag Area View
struct DragAreaView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        return DragView()
    }
    func updateNSView(_ nsView: NSView, context: Context) {}
}

class DragView: NSView {
    override func mouseDown(with event: NSEvent) {
        window?.performDrag(with: event)
    }
}

// MARK: - Key Event Handling Extension
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

// MARK: - FourCharCode Extension
extension String {
    var fourCharCodeValue: FourCharCode {
        var result: FourCharCode = 0
        if let data = self.data(using: .macOSRoman) {
            for byte in data {
                result = (result << 8) + FourCharCode(byte)
            }
        }
        return result
    }
}