import Foundation
import SwiftUI
import AppKit
import Carbon
import ServiceManagement

public enum HotkeyOption: String, CaseIterable, Codable, Identifiable {
    case cmdShiftV = "⌘⇧V"
    case optCmdV = "⌥⌘V"
    case ctrlOptV = "⌃⌥V"
    case cmdShiftC = "⌘⇧C"
    case cmdX = "⌘X"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .cmdShiftV: return "⌘⇧V (Recommended)"
        case .optCmdV: return "⌥⌘V"
        case .ctrlOptV: return "⌃⌥V"
        case .cmdShiftC: return "⌘⇧C"
        case .cmdX: return "⌘X (Legacy — overrides Cut)"
        }
    }

    public var keyCode: UInt32 {
        switch self {
        case .cmdShiftV, .optCmdV, .ctrlOptV:
            return UInt32(kVK_ANSI_V)
        case .cmdShiftC:
            return UInt32(kVK_ANSI_C)
        case .cmdX:
            return UInt32(kVK_ANSI_X)
        }
    }

    public var carbonModifiers: UInt32 {
        switch self {
        case .cmdShiftV, .cmdShiftC:
            return UInt32(cmdKey | shiftKey)
        case .optCmdV:
            return UInt32(cmdKey | optionKey)
        case .ctrlOptV:
            return UInt32(controlKey | optionKey)
        case .cmdX:
            return UInt32(cmdKey)
        }
    }
}

public final class AppSettings: ObservableObject {
    public static let shared = AppSettings()

    public static let defaultIgnoredBundleIDs: [String] = [
        "com.1password.1password",
        "com.agilebits.onepassword7",
        "com.agilebits.onepassword",
        "com.bitwarden.desktop",
        "com.lastpass.LastPass",
        "com.apple.keychainaccess",
        "com.apple.Passwords",
        "com.dashlane.dashlane",
        "org.keepassxc.keepassxc",
        "com.macpass.macpass",
        "com.enpass.app",
        "me.proton.pass.electron"
    ]

    private let defaults: UserDefaults
    private let enableSideEffects: Bool
    private var isLoading = true

    @Published public var appearanceMode: AppearanceMode = .system {
        didSet {
            guard !isLoading else { return }
            defaults.set(appearanceMode.rawValue, forKey: Keys.appearanceMode)
            if enableSideEffects { applyAppearanceMode() }
        }
    }

    @Published public var maxItems: Int = 100 {
        didSet {
            let clamped = min(max(maxItems, 20), 500)
            if maxItems != clamped {
                maxItems = clamped
                return
            }
            guard !isLoading else { return }
            defaults.set(maxItems, forKey: Keys.maxItems)
            if enableSideEffects {
                ClipboardManager.shared.enforceMaxItems()
            }
        }
    }

    @Published public var updateInterval: Double = 0.5 {
        didSet {
            let clamped = min(max(updateInterval, 0.2), 5.0)
            if updateInterval != clamped {
                updateInterval = clamped
                return
            }
            guard !isLoading else { return }
            defaults.set(updateInterval, forKey: Keys.updateInterval)
            if enableSideEffects {
                ClipboardManager.shared.restartMonitoring()
            }
        }
    }

    @Published public var autoUpdateEnabled: Bool = true {
        didSet {
            guard !isLoading else { return }
            defaults.set(autoUpdateEnabled, forKey: Keys.autoUpdateEnabled)
            if enableSideEffects {
                if autoUpdateEnabled {
                    AppUpdateManager.shared.startPeriodicCheck()
                } else {
                    AppUpdateManager.shared.stopPeriodicCheck()
                }
            }
        }
    }

    @Published public var checkUpdateInterval: Double = 24.0 {
        didSet {
            guard !isLoading else { return }
            defaults.set(checkUpdateInterval, forKey: Keys.checkUpdateInterval)
            if enableSideEffects && autoUpdateEnabled {
                AppUpdateManager.shared.startPeriodicCheck()
            }
        }
    }

    @Published public var autoInstallUpdates: Bool = false {
        didSet {
            guard !isLoading else { return }
            defaults.set(autoInstallUpdates, forKey: Keys.autoInstallUpdates)
        }
    }

    @Published public var compactMode: Bool = false {
        didSet {
            guard !isLoading else { return }
            defaults.set(compactMode, forKey: Keys.compactMode)
        }
    }

    @Published public var showNotifications: Bool = true {
        didSet {
            guard !isLoading else { return }
            defaults.set(showNotifications, forKey: Keys.showNotifications)
        }
    }

    @Published public var watchScreenshots: Bool = true {
        didSet {
            guard !isLoading else { return }
            defaults.set(watchScreenshots, forKey: Keys.watchScreenshots)
            if enableSideEffects {
                ClipboardManager.shared.updateScreenshotWatching()
            }
        }
    }

    @Published public var hotkeyOption: HotkeyOption = .cmdShiftV {
        didSet {
            guard !isLoading else { return }
            defaults.set(hotkeyOption.rawValue, forKey: Keys.hotkeyOption)
            if enableSideEffects {
                NotificationCenter.default.post(name: .hotkeyDidChange, object: hotkeyOption)
            }
        }
    }

    @Published public var enableSmartDetection: Bool = true {
        didSet {
            guard !isLoading else { return }
            defaults.set(enableSmartDetection, forKey: Keys.enableSmartDetection)
        }
    }

    @Published public var enableiCloudSync: Bool = false {
        didSet {
            guard !isLoading else { return }
            defaults.set(enableiCloudSync, forKey: Keys.enableiCloudSync)
        }
    }

    @Published public var isPasswordManagerExclusionEnabled: Bool = true {
        didSet {
            guard !isLoading else { return }
            defaults.set(isPasswordManagerExclusionEnabled, forKey: Keys.isPasswordManagerExclusionEnabled)
        }
    }

    @Published public var ignoreConcealedPasteboard: Bool = true {
        didSet {
            guard !isLoading else { return }
            defaults.set(ignoreConcealedPasteboard, forKey: Keys.ignoreConcealedPasteboard)
        }
    }

    @Published public var ignoredBundleIDs: [String] = AppSettings.defaultIgnoredBundleIDs {
        didSet {
            guard !isLoading else { return }
            defaults.set(ignoredBundleIDs, forKey: Keys.ignoredBundleIDs)
        }
    }

    @Published public var isOCREnabled: Bool = true {
        didSet {
            guard !isLoading else { return }
            defaults.set(isOCREnabled, forKey: Keys.isOCREnabled)
        }
    }

    @Published public var isDirectPasteEnabled: Bool = true {
        didSet {
            guard !isLoading else { return }
            defaults.set(isDirectPasteEnabled, forKey: Keys.isDirectPasteEnabled)
        }
    }

    @Published public var openNearCursor: Bool = true {
        didSet {
            guard !isLoading else { return }
            defaults.set(openNearCursor, forKey: Keys.openNearCursor)
        }
    }

    @Published public var preservePinnedOnClear: Bool = true {
        didSet {
            guard !isLoading else { return }
            defaults.set(preservePinnedOnClear, forKey: Keys.preservePinnedOnClear)
        }
    }

    @Published public var launchAtLogin: Bool = false {
        didSet {
            guard !isLoading else { return }
            defaults.set(launchAtLogin, forKey: Keys.launchAtLogin)
            if enableSideEffects {
                updateLaunchAtLogin(launchAtLogin)
            }
        }
    }

    @Published public var launchAtLoginError: String?

    public var globalHotkey: String {
        hotkeyOption.rawValue
    }

    private enum Keys {
        static let appearanceMode = "AppearanceMode"
        static let maxItems = "MaxItems"
        static let updateInterval = "UpdateInterval"
        static let autoUpdateEnabled = "AutoUpdateEnabled"
        static let checkUpdateInterval = "CheckUpdateInterval"
        static let autoInstallUpdates = "AutoInstallUpdates"
        static let compactMode = "CompactMode"
        static let showNotifications = "ShowNotifications"
        static let watchScreenshots = "WatchScreenshots"
        static let hotkeyOption = "HotkeyOption"
        static let enableSmartDetection = "EnableSmartDetection"
        static let enableiCloudSync = "EnableiCloudSync"
        static let isPasswordManagerExclusionEnabled = "IsPasswordManagerExclusionEnabled"
        static let ignoreConcealedPasteboard = "IgnoreConcealedPasteboard"
        static let ignoredBundleIDs = "IgnoredBundleIDs"
        static let isOCREnabled = "IsOCREnabled"
        static let isDirectPasteEnabled = "IsDirectPasteEnabled"
        static let openNearCursor = "OpenNearCursor"
        static let preservePinnedOnClear = "PreservePinnedOnClear"
        static let launchAtLogin = "LaunchAtLogin"
    }

    public init(defaults: UserDefaults = .standard, enableSideEffects: Bool = true) {
        self.defaults = defaults
        self.enableSideEffects = enableSideEffects
        loadSettings()
        if enableSideEffects {
            applyAppearanceMode()
        }
        isLoading = false
    }

    private func bool(forKey key: String, default defaultValue: Bool) -> Bool {
        defaults.object(forKey: key) != nil ? defaults.bool(forKey: key) : defaultValue
    }

    private func loadSettings() {
        if let appearanceModeString = defaults.string(forKey: Keys.appearanceMode),
           let mode = AppearanceMode(rawValue: appearanceModeString) {
            self.appearanceMode = mode
        }

        let savedMaxItems = defaults.integer(forKey: Keys.maxItems)
        if savedMaxItems > 0 {
            self.maxItems = min(max(savedMaxItems, 20), 500)
        }

        let savedUpdateInterval = defaults.double(forKey: Keys.updateInterval)
        if savedUpdateInterval > 0 {
            self.updateInterval = min(max(savedUpdateInterval, 0.2), 5.0)
        }

        self.autoUpdateEnabled = bool(forKey: Keys.autoUpdateEnabled, default: true)
        self.autoInstallUpdates = bool(forKey: Keys.autoInstallUpdates, default: false)
        self.compactMode = bool(forKey: Keys.compactMode, default: false)
        self.showNotifications = bool(forKey: Keys.showNotifications, default: true)
        self.watchScreenshots = bool(forKey: Keys.watchScreenshots, default: true)
        self.enableSmartDetection = bool(forKey: Keys.enableSmartDetection, default: true)
        self.enableiCloudSync = bool(forKey: Keys.enableiCloudSync, default: false)
        self.isPasswordManagerExclusionEnabled = bool(forKey: Keys.isPasswordManagerExclusionEnabled, default: true)
        self.ignoreConcealedPasteboard = bool(forKey: Keys.ignoreConcealedPasteboard, default: true)
        self.isOCREnabled = bool(forKey: Keys.isOCREnabled, default: true)
        self.isDirectPasteEnabled = bool(forKey: Keys.isDirectPasteEnabled, default: true)
        self.openNearCursor = bool(forKey: Keys.openNearCursor, default: true)
        self.preservePinnedOnClear = bool(forKey: Keys.preservePinnedOnClear, default: true)

        if let savedHotkey = defaults.string(forKey: Keys.hotkeyOption),
           let option = HotkeyOption(rawValue: savedHotkey) {
            self.hotkeyOption = option
        }

        let savedCheckInterval = defaults.double(forKey: Keys.checkUpdateInterval)
        if savedCheckInterval > 0 {
            self.checkUpdateInterval = savedCheckInterval
        }

        if let savedIgnored = defaults.stringArray(forKey: Keys.ignoredBundleIDs) {
            self.ignoredBundleIDs = savedIgnored
        }

        if enableSideEffects {
            self.launchAtLogin = SMAppService.mainApp.status == .enabled
        } else {
            self.launchAtLogin = bool(forKey: Keys.launchAtLogin, default: false)
        }
    }

    public func addIgnoredBundleID(_ bundleID: String) {
        let trimmed = bundleID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !ignoredBundleIDs.contains(trimmed) else { return }
        ignoredBundleIDs = ignoredBundleIDs + [trimmed]
    }

    public func removeIgnoredBundleID(_ bundleID: String) {
        ignoredBundleIDs = ignoredBundleIDs.filter { $0 != bundleID }
    }

    public func resetIgnoredBundleIDs() {
        ignoredBundleIDs = Self.defaultIgnoredBundleIDs
    }

    private func updateLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            launchAtLoginError = nil
        } catch {
            launchAtLoginError = "Launch at Login requires running ClipboardManager from /Applications."
            isLoading = true
            launchAtLogin = SMAppService.mainApp.status == .enabled
            isLoading = false
        }
    }

    public func applyAppearanceMode() {
        DispatchQueue.main.async {
            guard NSApp != nil else { return }
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
