import SwiftUI
import AppKit
import Carbon
import UserNotifications

// MARK: - App Delegate (Single Global Hotkey Owner)
public final class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private var hotkeyObserver: NSObjectProtocol?

    public func applicationDidFinishLaunching(_ notification: Notification) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, error in
            if let error {
                print("Notification permission error: \(error)")
            }
        }
        UNUserNotificationCenter.current().delegate = self

        let updateAction = UNNotificationAction(identifier: "UPDATE_NOW", title: "Update Now", options: .foreground)
        let laterAction = UNNotificationAction(identifier: "LATER", title: "Later", options: [])
        let updateCategory = UNNotificationCategory(
            identifier: "UPDATE_CATEGORY",
            actions: [updateAction, laterAction],
            intentIdentifiers: [],
            options: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([updateCategory])

        installHotkeyEventHandler()
        registerGlobalHotkey(AppSettings.shared.hotkeyOption)

        hotkeyObserver = NotificationCenter.default.addObserver(
            forName: .hotkeyDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.registerGlobalHotkey(AppSettings.shared.hotkeyOption)
        }

        _ = ClipboardManager.shared
        _ = AppUpdateManager.shared

        if AppSettings.shared.autoUpdateEnabled {
            AppUpdateManager.shared.startPeriodicCheck()
        }

        checkFirstRunAndShowWelcome()
        NSApp.setActivationPolicy(.accessory)
    }

    public func applicationWillTerminate(_ notification: Notification) {
        unregisterGlobalHotkey()
        if let hotkeyObserver {
            NotificationCenter.default.removeObserver(hotkeyObserver)
        }
    }

    public func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if response.notification.request.identifier == "UpdateAvailable" {
            if response.actionIdentifier == "UPDATE_NOW" || response.actionIdentifier == UNNotificationDefaultActionIdentifier {
                DispatchQueue.main.async {
                    AppUpdateManager.shared.downloadAndInstallUpdate()
                }
            }
        }
        completionHandler()
    }

    private func checkFirstRunAndShowWelcome() {
        let lastVersion = UserDefaults.standard.string(forKey: "LastRunVersion")
        let currentVersion = AppInfo.version

        if lastVersion != currentVersion {
            UserDefaults.standard.set(currentVersion, forKey: "LastRunVersion")
            if lastVersion == nil {
                let welcome = UNMutableNotificationContent()
                welcome.title = "Welcome to ClipboardManager v\(currentVersion)"
                welcome.body = "Press \(AppSettings.shared.globalHotkey) anytime to open history. Privacy protection & Vision OCR enabled."
                welcome.sound = .default
                let request = UNNotificationRequest(
                    identifier: "Welcome",
                    content: welcome,
                    trigger: UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
                )
                UNUserNotificationCenter.current().add(request)
            }
        }
    }

    private func installHotkeyEventHandler() {
        guard eventHandler == nil else { return }
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: OSType(kEventHotKeyPressed)
        )

        InstallEventHandler(GetApplicationEventTarget(), { _, _, _ -> OSStatus in
            ClipboardManager.shared.toggleWindow()
            return noErr
        }, 1, &eventType, nil, &eventHandler)
    }

    public func registerGlobalHotkey(_ option: HotkeyOption) {
        if let existing = hotKeyRef {
            UnregisterEventHotKey(existing)
            hotKeyRef = nil
        }

        let hotKeyID = EventHotKeyID(signature: "CBMG".fourCharCodeValue, id: 1)
        let status = RegisterEventHotKey(
            option.keyCode,
            option.carbonModifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        if status != noErr {
            print("Failed to register global hotkey \(option.rawValue) (OSStatus \(status))")
        }
    }

    private func unregisterGlobalHotkey() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
        if let eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
    }
}

// MARK: - Menu Bar View
public struct MenuBarView: View {
    @EnvironmentObject var clipboardManager: ClipboardManager
    @ObservedObject var appSettings = AppSettings.shared

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button("Open Clipboard History (\(appSettings.globalHotkey))") {
                clipboardManager.showWindow()
            }

            if clipboardManager.isPaused {
                Button("Resume Monitoring") {
                    clipboardManager.resumeMonitoring()
                }
            } else {
                Menu("Pause Monitoring") {
                    Button("Pause for 15 Minutes") {
                        clipboardManager.pauseMonitoring(for: 15 * 60)
                    }
                    Button("Pause for 1 Hour") {
                        clipboardManager.pauseMonitoring(for: 60 * 60)
                    }
                    Button("Pause Until Resumed") {
                        clipboardManager.pauseMonitoring(for: nil)
                    }
                }
            }

            let displayItems = Array(clipboardManager.items.prefix(5))
            if !displayItems.isEmpty {
                Divider()
                ForEach(displayItems) { item in
                    Button(action: {
                        if appSettings.isDirectPasteEnabled {
                            PasteService.shared.pasteDirectly(item, manager: clipboardManager)
                        } else {
                            clipboardManager.copyToClipboard(item)
                        }
                    }) {
                        HStack {
                            Image(systemName: item.typeIcon)
                            Text(item.displayContent)
                                .lineLimit(1)
                                .truncationMode(.tail)
                            if item.isPinned {
                                Image(systemName: "pin.fill")
                            }
                        }
                    }
                }
            }

            if !clipboardManager.items.isEmpty {
                Divider()
                if appSettings.preservePinnedOnClear {
                    Button("Clear Unpinned") {
                        clipboardManager.clearUnpinnedItems()
                    }
                }
                Button("Clear All History") {
                    clipboardManager.deleteAllItems(includePinned: true)
                }
            }

            Divider()

            Button("Check for Updates...") {
                AppUpdateManager.shared.checkForUpdates(manual: true)
            }

            Button("Settings...") {
                SettingsWindowController.shared.show()
            }

            Divider()

            Button("Quit Clipboard Manager") {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}

// MARK: - Menu Bar Icon
public struct CustomClipboardIcon: View {
    @ObservedObject var clipboardManager = ClipboardManager.shared

    public init() {}

    public var body: some View {
        Image(systemName: clipboardManager.isPaused ? "pause.circle" : "doc.on.clipboard")
    }
}

// MARK: - Window Drag Helper
struct DragAreaView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView { DragView() }
    func updateNSView(_ nsView: NSView, context: Context) {}
}

final class DragView: NSView {
    override func mouseDown(with event: NSEvent) {
        window?.performDrag(with: event)
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
