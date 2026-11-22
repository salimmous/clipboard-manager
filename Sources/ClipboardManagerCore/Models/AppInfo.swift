import Foundation

public enum AppInfo {
    public static let fallbackVersion = "1.4.0"
    public static let bundleIdentifier = "com.clipboardmanager.app"
    public static let repoOwnerAndName = "salimmous/clipboard-manager"

    public static var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? fallbackVersion
    }

    public static var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? version
    }

    public static var appSupportDirectory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let dir = base.appendingPathComponent("ClipboardManager", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
}

public extension Notification.Name {
    static let hotkeyDidChange = Notification.Name("ClipboardManagerHotkeyDidChange")
}
