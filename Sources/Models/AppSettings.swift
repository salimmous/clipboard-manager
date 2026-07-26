import Foundation
import SwiftUI
import AppKit

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
    @Published var autoInstallUpdates: Bool = false {
        didSet { if !isLoading { saveSettings() } }
    }
    @Published var compactMode: Bool = false {
        didSet { if !isLoading { saveSettings() } }
    }
    @Published var showNotifications: Bool = true {
        didSet { if !isLoading { saveSettings() } }
    }
    @Published var watchScreenshots: Bool = false {
        didSet { if !isLoading { saveSettings() } }
    }
    @Published var globalHotkey: String = "⌘X" {
        didSet { if !isLoading { saveSettings() } }
    }
    @Published var enableSmartDetection: Bool = true {
        didSet { if !isLoading { saveSettings() } }
    }
    @Published var enableiCloudSync: Bool = false {
        didSet { if !isLoading { saveSettings() } }
    }
    
    // MARK: - New Core Features Settings (Security, Privacy & OCR)
    @Published var isPasswordManagerExclusionEnabled: Bool = true {
        didSet { if !isLoading { saveSettings() } }
    }
    @Published var ignoredBundleIDs: [String] = [
        "com.agilebits.onepassword",
        "com.bitwarden.desktop",
        "com.lastpass.LastPass",
        "com.apple.keychainaccess",
        "com.dashlane.dashlane",
        "org.keepassxc.keepassxc",
        "com.macpass.macpass",
        "com.enpass.app"
    ] {
        didSet { if !isLoading { saveSettings() } }
    }
    @Published var isOCREnabled: Bool = true {
        didSet { if !isLoading { saveSettings() } }
    }
    @Published var isDirectPasteEnabled: Bool = true {
        didSet { if !isLoading { saveSettings() } }
    }
    
    init() {
        loadSettings()
        applyAppearanceMode()
        isLoading = false
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
        self.autoInstallUpdates = UserDefaults.standard.bool(forKey: "AutoInstallUpdates")
        self.compactMode = UserDefaults.standard.bool(forKey: "CompactMode")
        self.showNotifications = UserDefaults.standard.bool(forKey: "ShowNotifications")
        self.watchScreenshots = UserDefaults.standard.bool(forKey: "WatchScreenshots")
        self.globalHotkey = UserDefaults.standard.string(forKey: "GlobalHotkey") ?? "⌘X"
        self.enableSmartDetection = UserDefaults.standard.bool(forKey: "EnableSmartDetection")
        self.enableiCloudSync = UserDefaults.standard.bool(forKey: "EnableiCloudSync")
        
        let savedCheckInterval = UserDefaults.standard.double(forKey: "CheckUpdateInterval")
        if savedCheckInterval > 0 {
            self.checkUpdateInterval = savedCheckInterval
        }
        
        if UserDefaults.standard.object(forKey: "IsPasswordManagerExclusionEnabled") != nil {
            self.isPasswordManagerExclusionEnabled = UserDefaults.standard.bool(forKey: "IsPasswordManagerExclusionEnabled")
        }
        
        if let savedIgnored = UserDefaults.standard.stringArray(forKey: "IgnoredBundleIDs") {
            self.ignoredBundleIDs = savedIgnored
        }
        
        if UserDefaults.standard.object(forKey: "IsOCREnabled") != nil {
            self.isOCREnabled = UserDefaults.standard.bool(forKey: "IsOCREnabled")
        }
        
        if UserDefaults.standard.object(forKey: "IsDirectPasteEnabled") != nil {
            self.isDirectPasteEnabled = UserDefaults.standard.bool(forKey: "IsDirectPasteEnabled")
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
        UserDefaults.standard.set(watchScreenshots, forKey: "WatchScreenshots")
        UserDefaults.standard.set(globalHotkey, forKey: "GlobalHotkey")
        UserDefaults.standard.set(enableSmartDetection, forKey: "EnableSmartDetection")
        UserDefaults.standard.set(enableiCloudSync, forKey: "EnableiCloudSync")
        UserDefaults.standard.set(checkUpdateInterval, forKey: "CheckUpdateInterval")
        UserDefaults.standard.set(isPasswordManagerExclusionEnabled, forKey: "IsPasswordManagerExclusionEnabled")
        UserDefaults.standard.set(ignoredBundleIDs, forKey: "IgnoredBundleIDs")
        UserDefaults.standard.set(isOCREnabled, forKey: "IsOCREnabled")
        UserDefaults.standard.set(isDirectPasteEnabled, forKey: "IsDirectPasteEnabled")
        
        UserDefaults.standard.synchronize()
        applyAppearanceMode()
        
        ClipboardManager.shared.restartMonitoring()
        if autoUpdateEnabled {
            AppUpdateManager.shared.startPeriodicCheck()
        }
        ClipboardManager.shared.updateScreenshotWatching()
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
