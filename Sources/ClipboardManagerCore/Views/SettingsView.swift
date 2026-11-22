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
            contentRect: NSRect(x: 0, y: 0, width: 740, height: 540),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        win.minSize = NSSize(width: 680, height: 480)
        win.center()
        win.contentView = NSHostingView(rootView: rootView)
        win.title = "Settings"
        win.titleVisibility = .hidden
        win.titlebarAppearsTransparent = true
        win.styleMask.insert(.fullSizeContentView)
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

// MARK: - Sidebar Navigation Model
enum SettingsTab: String, CaseIterable, Identifiable {
    case general = "General"
    case appearance = "Appearance"
    case privacy = "Privacy & Data"
    case integrations = "Integrations"
    case updates = "Updates"
    case about = "About"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .general: return "gearshape.fill"
        case .appearance: return "paintbrush.fill"
        case .privacy: return "lock.shield.fill"
        case .integrations: return "puzzlepiece.extension.fill"
        case .updates: return "arrow.down.circle.fill"
        case .about: return "info.circle.fill"
        }
    }

    var badgeColor: Color {
        switch self {
        case .general: return .blue
        case .appearance: return .purple
        case .privacy: return .red
        case .integrations: return .teal
        case .updates: return .orange
        case .about: return .gray
        }
    }

    var subtitle: String {
        switch self {
        case .general: return "Shortcuts, paste behavior, startup & capture"
        case .appearance: return "Theme colors, layout density & popup placement"
        case .privacy: return "Password exclusion, OCR, auto-clear & iCloud"
        case .integrations: return "Webhooks, email & notes apps"
        case .updates: return "Automatic release checks & installation"
        case .about: return "Version info, credits & links"
        }
    }
}

// MARK: - Native Sidebar Visual Effect
private struct SidebarBackgroundView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .sidebar
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

// MARK: - Main Settings View
public struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var clipboardManager: ClipboardManager
    @State private var selectedTab: SettingsTab = .general

    public init() {}

    public var body: some View {
        HStack(spacing: 0) {
            // Left Native Sidebar
            VStack(alignment: .leading, spacing: 0) {
                // App Mini Header (padded below traffic lights)
                HStack(spacing: 10) {
                    Image(nsImage: NSApp.applicationIconImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 30, height: 30)
                        .cornerRadius(7)

                    VStack(alignment: .leading, spacing: 1) {
                        Text("Clipboard")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.primary)
                        Text("v\(AppInfo.version)")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.top, 36)
                .padding(.bottom, 16)
                .background(DragAreaView())

                // Sidebar Items
                VStack(spacing: 3) {
                    ForEach(SettingsTab.allCases) { tab in
                        SidebarRow(
                            tab: tab,
                            isSelected: selectedTab == tab
                        ) {
                            selectedTab = tab
                        }
                    }
                }
                .padding(.horizontal, 10)

                Spacer()
            }
            .frame(width: 196)
            .background(SidebarBackgroundView())

            Divider()

            // Right Content Pane
            VStack(alignment: .leading, spacing: 0) {
                // Pane Header
                VStack(alignment: .leading, spacing: 3) {
                    Text(selectedTab.rawValue)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                    Text(selectedTab.subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 24)
                .padding(.top, 26)
                .padding(.bottom, 14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(DragAreaView())

                Divider()

                // Active Tab Content
                Group {
                    switch selectedTab {
                    case .general:
                        GeneralSettingsPane(settings: settings)
                    case .appearance:
                        AppearanceSettingsPane(settings: settings)
                    case .privacy:
                        PrivacySettingsPane(
                            settings: settings,
                            scheduledClear: clipboardManager.scheduledClear,
                            iCloudSync: clipboardManager.iCloudSync
                        )
                    case .integrations:
                        IntegrationsSettingsPane(integrations: clipboardManager.integrations)
                    case .updates:
                        UpdatesSettingsPane(settings: settings, updater: AppUpdateManager.shared)
                    case .about:
                        AboutSettingsPane()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(minWidth: 680, minHeight: 480)
    }
}

private struct SidebarRow: View {
    let tab: SettingsTab
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(tab.badgeColor)
                        .frame(width: 24, height: 24)
                    Image(systemName: tab.icon)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                }

                Text(tab.rawValue)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .white : .primary)

                Spacer()
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 7)
                    .fill(
                        isSelected
                            ? Color.accentColor
                            : (isHovered ? Color.primary.opacity(0.06) : Color.clear)
                    )
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - General Pane
private struct GeneralSettingsPane: View {
    @ObservedObject var settings: AppSettings
    @State private var hasAccessibility = PasteService.shared.hasAccessibilityPermission

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                SettingsSection(title: "Shortcut & Startup") {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Global Toggle Shortcut")
                                .font(.system(size: 13, weight: .medium))
                            Text("Show or hide clipboard history from any application")
                                .font(.system(size: 11.5))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Picker("", selection: $settings.hotkeyOption) {
                            ForEach(HotkeyOption.allCases) { option in
                                Text(option.displayName).tag(option)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 205)
                    }

                    Divider()

                    SettingsToggleRow(
                        title: "Launch at Login",
                        subtitle: "Start Clipboard Manager automatically when signing into macOS",
                        isOn: $settings.launchAtLogin
                    )

                    if let error = settings.launchAtLoginError {
                        HStack(spacing: 6) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.orange)
                            Text(error)
                                .font(.system(size: 11.5))
                                .foregroundColor(.orange)
                        }
                    }
                }

                SettingsSection(title: "Clipboard & Direct Paste") {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("History Limit")
                                .font(.system(size: 13, weight: .medium))
                            Text("Pinned items are always protected first when trimming old entries")
                                .font(.system(size: 11.5))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text("\(settings.maxItems) items")
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.primary.opacity(0.06))
                            .cornerRadius(6)
                        Stepper("", value: $settings.maxItems, in: 20...500, step: 20)
                            .labelsHidden()
                    }

                    Divider()

                    SettingsToggleRow(
                        title: "Direct Auto-Paste (⌘V)",
                        subtitle: "Automatically paste selected items directly into the active app",
                        isOn: $settings.isDirectPasteEnabled
                    )

                    // Accessibility Permission Pill
                    HStack(spacing: 8) {
                        Image(systemName: hasAccessibility ? "checkmark.shield.fill" : "exclamationmark.triangle.fill")
                            .foregroundColor(hasAccessibility ? .green : .orange)
                            .font(.system(size: 13))

                        Text(hasAccessibility ? "Accessibility permission granted" : "Accessibility permission needed for automatic ⌘V paste")
                            .font(.system(size: 11.5, weight: .medium))
                            .foregroundColor(hasAccessibility ? .primary : .orange)

                        Spacer()

                        if !hasAccessibility {
                            Button("Grant Permission") {
                                hasAccessibility = PasteService.shared.requestAccessibilityPermission()
                                if !hasAccessibility {
                                    PasteService.shared.openAccessibilitySettings()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                        } else {
                            Button("Check Again") {
                                hasAccessibility = PasteService.shared.hasAccessibilityPermission
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(hasAccessibility ? Color.green.opacity(0.08) : Color.orange.opacity(0.1))
                    )

                    Divider()

                    SettingsToggleRow(
                        title: "Keep Pinned Items on Clear",
                        subtitle: "Clear all removes only unpinned items by default",
                        isOn: $settings.preservePinnedOnClear
                    )
                }

                SettingsSection(title: "Capture & Notifications") {
                    SettingsToggleRow(
                        title: "Smart Notifications",
                        subtitle: "Display a macOS notification banner when new items are copied",
                        isOn: $settings.showNotifications
                    )

                    Divider()

                    SettingsToggleRow(
                        title: "Auto-Copy Screenshots",
                        subtitle: "Automatically add newly saved macOS screenshots to history",
                        isOn: $settings.watchScreenshots
                    )
                }
            }
            .padding(22)
        }
        .onAppear {
            hasAccessibility = PasteService.shared.hasAccessibilityPermission
        }
    }
}

// MARK: - Appearance Pane
private struct AppearanceSettingsPane: View {
    @ObservedObject var settings: AppSettings

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                SettingsSection(title: "Theme") {
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(AppearanceMode.allCases, id: \.self) { mode in
                            ThemeSwatchCard(
                                mode: mode,
                                isSelected: settings.appearanceMode == mode
                            ) {
                                settings.appearanceMode = mode
                            }
                        }
                    }
                }

                SettingsSection(title: "Popup Window") {
                    SettingsToggleRow(
                        title: "Compact Mode",
                        subtitle: "Smaller popup window (380×400) instead of standard (420×450)",
                        isOn: $settings.compactMode
                    )

                    Divider()

                    SettingsToggleRow(
                        title: "Open Near Mouse Cursor",
                        subtitle: "Position popup near your pointer on the active screen",
                        isOn: $settings.openNearCursor
                    )
                }
            }
            .padding(22)
        }
    }
}

private struct ThemeSwatchCard: View {
    let mode: AppearanceMode
    let isSelected: Bool
    let action: () -> Void

    private var previewColors: [Color] {
        switch mode {
        case .system: return [Color(NSColor.windowBackgroundColor), Color.accentColor.opacity(0.35)]
        case .light: return [Color.white, Color.gray.opacity(0.15)]
        case .dark: return [Color(white: 0.14), Color(white: 0.24)]
        case .blue: return [Color.blue.opacity(0.35), Color.cyan.opacity(0.2)]
        case .purple: return [Color.purple.opacity(0.35), Color.pink.opacity(0.2)]
        case .green: return [Color.green.opacity(0.35), Color.mint.opacity(0.2)]
        case .orange: return [Color.orange.opacity(0.35), Color.yellow.opacity(0.2)]
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(LinearGradient(colors: previewColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(height: 44)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isSelected ? Color.accentColor : Color.primary.opacity(0.14), lineWidth: isSelected ? 2 : 1)
                        )

                    if mode == .system {
                        Image(systemName: "circle.lefthalf.filled")
                            .font(.system(size: 16))
                            .foregroundColor(.primary.opacity(0.75))
                    } else if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(mode == .dark ? .white : .accentColor)
                    }
                }

                Text(mode.displayName)
                    .font(.system(size: 11.5, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .accentColor : .primary)
                    .lineLimit(1)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Privacy & Data Pane
private struct PrivacySettingsPane: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var scheduledClear: ScheduledClearManager
    @ObservedObject var iCloudSync: iCloudSyncManager

    @State private var newBundleID = ""
    @State private var lastManualClearCount: Int?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                SettingsSection(title: "Password & Sensitive Data Protection") {
                    SettingsToggleRow(
                        title: "Ignore Concealed & Transient Data",
                        subtitle: "Automatically skips macOS ConcealedType & TransientType items from password managers and browser extensions",
                        isOn: $settings.ignoreConcealedPasteboard
                    )

                    Divider()

                    SettingsToggleRow(
                        title: "Ignore Specific Apps (Bundle IDs)",
                        subtitle: "Never record clipboard items while any app below is active",
                        isOn: $settings.isPasswordManagerExclusionEnabled
                    )

                    if settings.isPasswordManagerExclusionEnabled {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                TextField("Bundle ID (e.g. com.1password.1password)", text: $newBundleID)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.system(size: 12))
                                    .onSubmit {
                                        addBundleID()
                                    }

                                Button("Add") {
                                    addBundleID()
                                }
                                .disabled(newBundleID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                                Button("Reset") {
                                    settings.resetIgnoredBundleIDs()
                                }
                            }

                            ScrollView {
                                VStack(spacing: 4) {
                                    ForEach(settings.ignoredBundleIDs, id: \.self) { bundleID in
                                        HStack {
                                            Text(bundleID)
                                                .font(.system(size: 11.5, design: .monospaced))
                                                .foregroundColor(.primary)
                                            Spacer()
                                            Button(action: { settings.removeIgnoredBundleID(bundleID) }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(.secondary)
                                            }
                                            .buttonStyle(.plain)
                                            .help("Remove \(bundleID)")
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Color(NSColor.textBackgroundColor))
                                        .cornerRadius(6)
                                    }
                                }
                                .padding(6)
                            }
                            .frame(height: 128)
                            .background(Color.primary.opacity(0.03))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                            )
                            .cornerRadius(8)
                        }
                    }
                }

                SettingsSection(title: "Local Intelligence") {
                    SettingsToggleRow(
                        title: "Vision OCR Image Text Recognition",
                        subtitle: "Extract searchable text from copied images 100% locally on-device",
                        isOn: $settings.isOCREnabled
                    )

                    Divider()

                    SettingsToggleRow(
                        title: "Smart Content Detection",
                        subtitle: "Detect emails, phone numbers, street addresses, and hex colors",
                        isOn: $settings.enableSmartDetection
                    )
                }

                SettingsSection(title: "Scheduled Auto-Clear") {
                    SettingsToggleRow(
                        title: "Enable Automatic Cleanup",
                        subtitle: "Remove old clipboard entries after a chosen retention window",
                        isOn: $scheduledClear.isEnabled
                    )

                    if scheduledClear.isEnabled {
                        Divider()

                        HStack {
                            Text("Delete items older than")
                                .font(.system(size: 13, weight: .medium))
                            Spacer()
                            Picker("", selection: Binding(
                                get: { ScheduledClearManager.ClearInterval.matching(scheduledClear.clearInterval) },
                                set: { scheduledClear.setClearInterval($0) }
                            )) {
                                ForEach(ScheduledClearManager.ClearInterval.allCases) { interval in
                                    Text(interval.rawValue).tag(interval)
                                }
                            }
                            .labelsHidden()
                            .frame(width: 130)
                        }

                        Divider()

                        SettingsToggleRow(
                            title: "Protect Pinned Items",
                            subtitle: "Keep pinned entries during scheduled cleanup",
                            isOn: $scheduledClear.clearOnlyUnpinned
                        )

                        HStack {
                            if let count = lastManualClearCount {
                                Text("Removed \(count) item\(count == 1 ? "" : "s")")
                                    .font(.system(size: 11.5))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Button("Run Cleanup Now") {
                                lastManualClearCount = scheduledClear.performScheduledClear()
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                }

                SettingsSection(title: "iCloud Sync") {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Sync Text & URLs via CloudKit")
                                .font(.system(size: 13, weight: .medium))
                            Text(iCloudSync.statusMessage.isEmpty ? "Sync clipboard across your Macs" : iCloudSync.statusMessage)
                                .font(.system(size: 11.5))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { iCloudSync.syncEnabled },
                            set: { iCloudSync.toggleSync($0) }
                        ))
                        .toggleStyle(.switch)
                        .labelsHidden()
                        .disabled(!iCloudSync.isEntitlementAvailable)
                    }
                }
            }
            .padding(22)
        }
    }

    private func addBundleID() {
        settings.addIgnoredBundleID(newBundleID)
        newBundleID = ""
    }
}

// MARK: - Integrations Pane
private struct IntegrationsSettingsPane: View {
    @ObservedObject var integrations: IntegrationManager

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                SettingsSection(title: "Webhooks") {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Slack Webhook URL")
                                .font(.system(size: 13, weight: .medium))
                            Spacer()
                            StatusDot(isActive: integrations.isSlackConfigured)
                        }
                        TextField("https://hooks.slack.com/services/...", text: $integrations.slackWebhookURL)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 12))
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Discord Webhook URL")
                                .font(.system(size: 13, weight: .medium))
                            Spacer()
                            StatusDot(isActive: integrations.isDiscordConfigured)
                        }
                        TextField("https://discord.com/api/webhooks/...", text: $integrations.discordWebhookURL)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 12))
                    }
                }

                SettingsSection(title: "Default Apps") {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Email Client")
                                .font(.system(size: 13, weight: .medium))
                            Text("Used by Share → Compose Email")
                                .font(.system(size: 11.5))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Picker("", selection: $integrations.defaultEmailApp) {
                            ForEach(IntegrationManager.EmailApp.allCases, id: \.self) { app in
                                Text(app.rawValue).tag(app)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 170)
                    }

                    Divider()

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Notes App")
                                .font(.system(size: 13, weight: .medium))
                            Text("Used by Share → Save to Notes")
                                .font(.system(size: 11.5))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Picker("", selection: $integrations.defaultNotesApp) {
                            ForEach(IntegrationManager.NotesApp.allCases, id: \.self) { app in
                                Text(app.rawValue).tag(app)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 170)
                    }
                }
            }
            .padding(22)
        }
    }
}

private struct StatusDot: View {
    let isActive: Bool

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(isActive ? Color.green : Color.secondary.opacity(0.4))
                .frame(width: 7, height: 7)
            Text(isActive ? "Ready" : "Not configured")
                .font(.system(size: 11))
                .foregroundColor(isActive ? .green : .secondary)
        }
    }
}

// MARK: - Updates Pane
private struct UpdatesSettingsPane: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var updater: AppUpdateManager

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                SettingsSection(title: "Current Build") {
                    HStack(spacing: 14) {
                        Image(nsImage: NSApp.applicationIconImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 44, height: 44)
                            .cornerRadius(10)

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Clipboard Manager v\(AppInfo.version)")
                                .font(.system(size: 14, weight: .semibold))
                            Text(updater.statusMessage.isEmpty ? "Checks GitHub Releases for updates" : updater.statusMessage)
                                .font(.system(size: 12))
                                .foregroundColor(updater.isUpdateAvailable ? .green : .secondary)
                        }

                        Spacer()

                        if updater.isChecking {
                            ProgressView()
                                .controlSize(.small)
                        }

                        if updater.isUpdateAvailable {
                            Button("Install \(updater.latestVersion)") {
                                updater.downloadAndInstallUpdate()
                            }
                            .buttonStyle(.borderedProminent)
                        }

                        Button("Check Now") {
                            updater.checkForUpdates(manual: true)
                        }
                        .buttonStyle(.bordered)
                        .disabled(updater.isChecking)
                    }
                }

                SettingsSection(title: "Preferences") {
                    SettingsToggleRow(
                        title: "Check for Updates Automatically",
                        subtitle: "Periodically query GitHub Releases in the background",
                        isOn: $settings.autoUpdateEnabled
                    )

                    Divider()

                    SettingsToggleRow(
                        title: "Direct Install Flow",
                        subtitle: "Skip Save-to-Downloads choice and go straight to installer confirmation",
                        isOn: $settings.autoInstallUpdates
                    )
                }
            }
            .padding(22)
        }
    }
}

// MARK: - About Pane
private struct AboutSettingsPane: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 84, height: 84)
                .cornerRadius(18)
                .shadow(color: .black.opacity(0.15), radius: 8, y: 4)

            VStack(spacing: 6) {
                Text("Clipboard Manager")
                    .font(.system(size: 22, weight: .bold))

                Text("Version \(AppInfo.version)")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(Color.primary.opacity(0.06))
                    .clipShape(Capsule())
            }

            Text("Native macOS clipboard manager with Vision OCR, concealed pasteboard privacy, hex color previews, and instant direct paste.")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 380)

            VStack(spacing: 8) {
                Text("Created & Maintained by Salim Moustanir")
                    .font(.system(size: 13, weight: .medium))

                Link(destination: URL(string: "https://github.com/\(AppInfo.repoOwnerAndName)")!) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.right.square")
                        Text("github.com/\(AppInfo.repoOwnerAndName)")
                    }
                    .font(.system(size: 12.5, weight: .medium))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding(.top, 4)

            Spacer()

            Text("© 2026 Salim Moustanir. All rights reserved.")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
    }
}

// MARK: - Shared Settings Components
private struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.leading, 4)

            VStack(alignment: .leading, spacing: 12) {
                content
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(NSColor.controlBackgroundColor))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
            .cornerRadius(10)
        }
    }
}

private struct SettingsToggleRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                Text(subtitle)
                    .font(.system(size: 11.5))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .labelsHidden()
        }
    }
}
