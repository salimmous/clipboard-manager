import SwiftUI
import AppKit

// MARK: - Shared Settings Window Controller
public final class SettingsWindowController: NSObject, NSWindowDelegate {
    public static let shared = SettingsWindowController()
    private var window: NSWindow?

    public func show() {
        if let existing = window {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let rootView = SettingsView()
            .environmentObject(AppSettings.shared)
            .environmentObject(ClipboardManager.shared)

        let win = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 660, height: 520),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        win.center()
        win.contentView = NSHostingView(rootView: rootView)
        win.title = "Clipboard Manager Settings"
        win.isReleasedWhenClosed = false
        win.delegate = self
        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        self.window = win
    }

    public func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.orderOut(nil)
        return false
    }
}

public struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var clipboardManager: ClipboardManager

    public init() {}

    public var body: some View {
        TabView {
            GeneralSettingsView(settings: settings)
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            PrivacySettingsView(
                settings: settings,
                scheduledClear: clipboardManager.scheduledClear,
                iCloudSync: clipboardManager.iCloudSync
            )
            .tabItem {
                Label("Privacy & Data", systemImage: "lock.shield")
            }

            IntegrationsSettingsView(integrations: clipboardManager.integrations)
                .tabItem {
                    Label("Integrations", systemImage: "link")
                }

            UpdatesSettingsView(settings: settings, updater: AppUpdateManager.shared)
                .tabItem {
                    Label("Updates", systemImage: "arrow.triangle.2.circlepath")
                }

            AboutSettingsView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(minWidth: 640, minHeight: 500)
    }
}

// MARK: - General Tab
struct GeneralSettingsView: View {
    @ObservedObject var settings: AppSettings
    @State private var hasAccessibility = PasteService.shared.hasAccessibilityPermission

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Shortcuts & Startup
                settingsCard(title: "Shortcut & Startup", icon: "command", color: .purple) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Global Toggle Shortcut")
                                .font(.system(size: 13.5, weight: .medium))
                            Text("Opens or hides Clipboard Manager from any app")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Picker("", selection: $settings.hotkeyOption) {
                            ForEach(HotkeyOption.allCases) { option in
                                Text(option.displayName).tag(option)
                            }
                        }
                        .frame(width: 220)
                    }

                    Divider()

                    toggleRow(
                        title: "Launch at Login",
                        subtitle: "Automatically start Clipboard Manager when you sign in",
                        isOn: $settings.launchAtLogin
                    )

                    if let error = settings.launchAtLoginError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }

                // Behavior & Paste
                settingsCard(title: "Clipboard & Paste", icon: "doc.on.clipboard", color: .blue) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("History Limit: \(settings.maxItems) items")
                                .font(.system(size: 13.5, weight: .medium))
                            Text("Pinned items are protected first when trimming old entries")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Stepper("", value: $settings.maxItems, in: 20...500, step: 20)
                            .labelsHidden()
                    }

                    Divider()

                    toggleRow(
                        title: "Direct Auto-Paste (⌘V)",
                        subtitle: "Automatically paste selected item into the active app",
                        isOn: $settings.isDirectPasteEnabled
                    )

                    HStack {
                        Image(systemName: hasAccessibility ? "checkmark.shield.fill" : "exclamationmark.triangle.fill")
                            .foregroundColor(hasAccessibility ? .green : .orange)
                        Text(hasAccessibility ? "Accessibility permission granted" : "Accessibility permission required for auto-paste")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        if !hasAccessibility {
                            Button("Grant Permission") {
                                hasAccessibility = PasteService.shared.requestAccessibilityPermission()
                                if !hasAccessibility {
                                    PasteService.shared.openAccessibilitySettings()
                                }
                            }
                            .controlSize(.small)
                        } else {
                            Button("Refresh") {
                                hasAccessibility = PasteService.shared.hasAccessibilityPermission
                            }
                            .controlSize(.small)
                        }
                    }

                    Divider()

                    toggleRow(
                        title: "Open Near Mouse Cursor",
                        subtitle: "Position popup near your pointer on the active screen",
                        isOn: $settings.openNearCursor
                    )

                    Divider()

                    toggleRow(
                        title: "Keep Pinned Items on Clear",
                        subtitle: "The Clear button only removes unpinned items",
                        isOn: $settings.preservePinnedOnClear
                    )
                }

                // Appearance & Notifications
                settingsCard(title: "Appearance & Capture", icon: "paintbrush.fill", color: .orange) {
                    HStack {
                        Text("Theme")
                            .font(.system(size: 13.5, weight: .medium))
                        Spacer()
                        Picker("", selection: $settings.appearanceMode) {
                            ForEach(AppearanceMode.allCases, id: \.self) { mode in
                                Text(mode.displayName).tag(mode)
                            }
                        }
                        .frame(width: 180)
                    }

                    Divider()

                    toggleRow(
                        title: "Compact Mode",
                        subtitle: "Denser list layout and smaller popup window",
                        isOn: $settings.compactMode
                    )

                    Divider()

                    toggleRow(
                        title: "Smart Notifications",
                        subtitle: "Show notification banner when items are copied",
                        isOn: $settings.showNotifications
                    )

                    Divider()

                    toggleRow(
                        title: "Auto-Copy Screenshots",
                        subtitle: "Automatically capture newly saved macOS screenshots",
                        isOn: $settings.watchScreenshots
                    )
                }
            }
            .padding(16)
        }
        .onAppear {
            hasAccessibility = PasteService.shared.hasAccessibilityPermission
        }
    }
}

// MARK: - Privacy & Data Tab
struct PrivacySettingsView: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var scheduledClear: ScheduledClearManager
    @ObservedObject var iCloudSync: iCloudSyncManager

    @State private var newBundleID = ""
    @State private var lastManualClearCount: Int?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Security & Privacy
                settingsCard(title: "Security & Password Protection", icon: "lock.shield.fill", color: .red) {
                    toggleRow(
                        title: "Ignore Concealed & Transient Data",
                        subtitle: "Respects macOS ConcealedType/TransientType markers from password managers & extensions",
                        isOn: $settings.ignoreConcealedPasteboard
                    )

                    Divider()

                    toggleRow(
                        title: "Ignore Specific Apps (Bundle IDs)",
                        subtitle: "Skip clipboard capture while these apps are focused",
                        isOn: $settings.isPasswordManagerExclusionEnabled
                    )

                    if settings.isPasswordManagerExclusionEnabled {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                TextField("e.g. com.agilebits.onepassword", text: $newBundleID)
                                    .textFieldStyle(.roundedBorder)
                                Button("Add") {
                                    settings.addIgnoredBundleID(newBundleID)
                                    newBundleID = ""
                                }
                                .disabled(newBundleID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                                Button("Reset") {
                                    settings.resetIgnoredBundleIDs()
                                }
                            }

                            VStack(spacing: 4) {
                                ForEach(settings.ignoredBundleIDs, id: \.self) { bundleID in
                                    HStack {
                                        Text(bundleID)
                                            .font(.system(.caption, design: .monospaced))
                                        Spacer()
                                        Button(action: { settings.removeIgnoredBundleID(bundleID) }) {
                                            Image(systemName: "minus.circle.fill")
                                                .foregroundColor(.red.opacity(0.8))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color(NSColor.textBackgroundColor).opacity(0.6))
                                    .cornerRadius(5)
                                }
                            }
                        }
                    }

                    Divider()

                    toggleRow(
                        title: "Vision OCR Image Text Recognition",
                        subtitle: "Extract searchable text from copied images locally on-device",
                        isOn: $settings.isOCREnabled
                    )

                    Divider()

                    toggleRow(
                        title: "Smart Content Detection",
                        subtitle: "Detect emails, phone numbers, street addresses, and hex colors",
                        isOn: $settings.enableSmartDetection
                    )
                }

                // Scheduled Auto-Clear
                settingsCard(title: "Scheduled Auto-Clear", icon: "clock.arrow.circlepath", color: .blue) {
                    toggleRow(
                        title: "Enable Automatic Cleanup",
                        subtitle: "Automatically delete clipboard items older than selected age",
                        isOn: $scheduledClear.isEnabled
                    )

                    if scheduledClear.isEnabled {
                        Divider()

                        HStack {
                            Text("Delete items older than")
                                .font(.system(size: 13.5, weight: .medium))
                            Spacer()
                            Picker("", selection: Binding(
                                get: { ScheduledClearManager.ClearInterval.matching(scheduledClear.clearInterval) },
                                set: { scheduledClear.setClearInterval($0) }
                            )) {
                                ForEach(ScheduledClearManager.ClearInterval.allCases) { interval in
                                    Text(interval.rawValue).tag(interval)
                                }
                            }
                            .frame(width: 140)
                        }

                        toggleRow(
                            title: "Protect Pinned Items",
                            subtitle: "Keep pinned items during scheduled cleanup",
                            isOn: $scheduledClear.clearOnlyUnpinned
                        )

                        HStack {
                            if let count = lastManualClearCount {
                                Text("Removed \(count) item\(count == 1 ? "" : "s")")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Button("Run Cleanup Now") {
                                lastManualClearCount = scheduledClear.performScheduledClear()
                            }
                            .controlSize(.small)
                        }
                    }
                }

                // iCloud Sync
                settingsCard(title: "iCloud Sync", icon: "icloud.fill", color: .cyan) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Sync Text & URLs via CloudKit")
                                .font(.system(size: 13.5, weight: .medium))
                            Text(iCloudSync.statusMessage.isEmpty ? "Sync clipboard across your Macs" : iCloudSync.statusMessage)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { iCloudSync.syncEnabled },
                            set: { iCloudSync.toggleSync($0) }
                        ))
                        .toggleStyle(.switch)
                        .disabled(!iCloudSync.isEntitlementAvailable)
                    }
                }
            }
            .padding(16)
        }
    }
}

// MARK: - Integrations Tab
struct IntegrationsSettingsView: View {
    @ObservedObject var integrations: IntegrationManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                GroupBox("Slack Integration") {
                    VStack(alignment: .leading, spacing: 6) {
                        TextField("https://hooks.slack.com/services/...", text: $integrations.slackWebhookURL)
                            .textFieldStyle(.roundedBorder)
                        Text("Used by Share → Send to Slack in popup item menu.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(6)
                }

                GroupBox("Discord Integration") {
                    VStack(alignment: .leading, spacing: 6) {
                        TextField("https://discord.com/api/webhooks/...", text: $integrations.discordWebhookURL)
                            .textFieldStyle(.roundedBorder)
                        Text("Used by Share → Send to Discord in popup item menu.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(6)
                }

                GroupBox("Email Integration") {
                    Picker("Default Email App", selection: $integrations.defaultEmailApp) {
                        ForEach(IntegrationManager.EmailApp.allCases, id: \.self) { app in
                            Text(app.rawValue).tag(app)
                        }
                    }
                    .padding(6)
                }

                GroupBox("Notes Integration") {
                    Picker("Default Notes App", selection: $integrations.defaultNotesApp) {
                        ForEach(IntegrationManager.NotesApp.allCases, id: \.self) { app in
                            Text(app.rawValue).tag(app)
                        }
                    }
                    .padding(6)
                }
            }
            .padding(16)
        }
    }
}

// MARK: - Updates Tab
struct UpdatesSettingsView: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var updater: AppUpdateManager

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                settingsCard(title: "Automatic Updates", icon: "arrow.down.circle.fill", color: .orange) {
                    toggleRow(
                        title: "Check for Updates Automatically",
                        subtitle: "Periodically check GitHub Releases for newer versions",
                        isOn: $settings.autoUpdateEnabled
                    )

                    Divider()

                    toggleRow(
                        title: "Skip Prompt Before Installing",
                        subtitle: "Proceed directly to installer confirmation when downloading updates",
                        isOn: $settings.autoInstallUpdates
                    )
                }

                settingsCard(title: "Update Status", icon: "info.circle.fill", color: .blue) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Current Version: v\(AppInfo.version)")
                                .font(.subheadline.bold())
                            if !updater.statusMessage.isEmpty {
                                Text(updater.statusMessage)
                                    .font(.caption)
                                    .foregroundColor(updater.isUpdateAvailable ? .green : .secondary)
                            }
                        }
                        Spacer()
                        if updater.isChecking {
                            ProgressView()
                                .controlSize(.small)
                        }
                        if updater.isUpdateAvailable {
                            Button("Download \(updater.latestVersion)") {
                                updater.downloadAndInstallUpdate()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        Button("Check Now") {
                            updater.checkForUpdates(manual: true)
                        }
                        .disabled(updater.isChecking)
                    }
                }
            }
            .padding(16)
        }
    }
}

// MARK: - About Tab
struct AboutSettingsView: View {
    var body: some View {
        VStack(spacing: 14) {
            Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
                .resizable()
                .frame(width: 80, height: 80)
                .cornerRadius(16)

            Text("Clipboard Manager")
                .font(.title)
                .bold()

            Text("Version \(AppInfo.version)")
                .foregroundColor(.secondary)

            Text("Native macOS clipboard manager with Vision OCR, concealed pasteboard privacy, color previews, and direct paste.")
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            VStack(spacing: 6) {
                Text("Created & Maintained by Salim Moustanir")
                    .font(.system(size: 13, weight: .semibold))

                Link("GitHub: \(AppInfo.repoOwnerAndName)", destination: URL(string: "https://github.com/\(AppInfo.repoOwnerAndName)")!)
                    .font(.system(size: 12, weight: .medium))
            }
            .padding(.vertical, 4)

            Spacer()

            Text("© 2026 Salim Moustanir. All rights reserved.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(20)
    }
}

// MARK: - Shared Settings UI Helpers
private func settingsCard<Content: View>(
    title: String,
    icon: String,
    color: Color,
    @ViewBuilder content: () -> Content
) -> some View {
    VStack(alignment: .leading, spacing: 12) {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 15, weight: .semibold))
            Text(title)
                .font(.system(size: 16, weight: .semibold))
            Spacer()
        }
        VStack(alignment: .leading, spacing: 12) {
            content()
        }
    }
    .padding(16)
    .background(Color(NSColor.controlBackgroundColor))
    .clipShape(RoundedRectangle(cornerRadius: 12))
}

private func toggleRow(title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
    HStack {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 13.5, weight: .medium))
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        Spacer()
        Toggle("", isOn: isOn)
            .toggleStyle(.switch)
            .labelsHidden()
    }
}
