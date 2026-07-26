import SwiftUI
import AppKit

struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings
    
    var body: some View {
        TabView {
            GeneralSettingsView(settings: settings)
                .tabItem {
                    Label("General", systemImage: "gear")
                }
            
            IntegrationsSettingsView()
                .tabItem {
                    Label("Integrations", systemImage: "link")
                }
            
            UpdatesSettingsView(settings: settings)
                .tabItem {
                    Label("Updates", systemImage: "arrow.triangle.2.circlepath")
                }
            
            AboutSettingsView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 650, height: 480)
    }
}

struct GeneralSettingsView: View {
    @ObservedObject var settings: AppSettings
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Security & Privacy Section (NEW)
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "lock.shield.fill")
                            .foregroundColor(.red)
                            .font(.system(size: 16, weight: .medium))
                        Text("Security & Privacy")
                            .font(.system(size: 18, weight: .semibold))
                        Spacer()
                    }
                    
                    VStack(spacing: 14) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Ignore Password Managers")
                                    .font(.system(size: 14, weight: .medium))
                                Text("Never save copied passwords from 1Password, Bitwarden, Keychain, etc.")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Toggle("", isOn: $settings.isPasswordManagerExclusionEnabled)
                                .toggleStyle(.switch)
                        }
                        
                        Divider()
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Vision OCR Image Text Recognition")
                                    .font(.system(size: 14, weight: .medium))
                                Text("Automatically extract text from copied images for search")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Toggle("", isOn: $settings.isOCREnabled)
                                .toggleStyle(.switch)
                        }
                        
                        Divider()
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Direct Auto-Paste (⌘V)")
                                    .font(.system(size: 14, weight: .medium))
                                Text("Automatically paste selected item into frontmost application")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Toggle("", isOn: $settings.isDirectPasteEnabled)
                                .toggleStyle(.switch)
                        }
                    }
                }
                .padding(18)
                .background(Color(NSColor.controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Appearance Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "paintbrush.fill")
                            .foregroundColor(.blue)
                            .font(.system(size: 16, weight: .medium))
                        Text("Appearance")
                            .font(.system(size: 18, weight: .semibold))
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
                .padding(18)
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
                        Spacer()
                    }
                    
                    VStack(spacing: 12) {
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
                        
                        Divider()
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Auto-Copy Screenshots")
                                    .font(.system(size: 14, weight: .medium))
                                Text("Automatically copy new screenshots to clipboard")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Toggle("", isOn: $settings.watchScreenshots)
                                .toggleStyle(.switch)
                        }
                    }
                }
                .padding(18)
                .background(Color(NSColor.controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(16)
        }
    }
}

struct UpdatesSettingsView: View {
    @ObservedObject var settings: AppSettings
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundColor(.orange)
                            .font(.system(size: 16, weight: .medium))
                        Text("Automatic Updates")
                            .font(.system(size: 18, weight: .semibold))
                        Spacer()
                    }
                    
                    VStack(spacing: 12) {
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
                    }
                }
                .padding(18)
                .background(Color(NSColor.controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                            .font(.system(size: 16, weight: .medium))
                        Text("Update Status")
                            .font(.system(size: 18, weight: .semibold))
                        Spacer()
                    }
                    
                    HStack {
                        Text("Current Version: v1.3.0")
                            .font(.subheadline)
                        Spacer()
                        Button("Check Now") {
                            AppUpdateManager.shared.checkForUpdates()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding(18)
                .background(Color(NSColor.controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(16)
        }
    }
}

struct AboutSettingsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
                .resizable()
                .frame(width: 80, height: 80)
                .cornerRadius(16)
            
            Text("Clipboard Manager")
                .font(.title)
                .bold()
            
            Text("Version 1.3.0")
                .foregroundColor(.secondary)
            
            Text("Native macOS clipboard manager with Vision OCR, Security & Privacy filters, and Smart Integrations.")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            
            Text("© 2026 All rights reserved.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

struct IntegrationsSettingsView: View {
    @StateObject private var integrations = IntegrationManager()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                GroupBox("Slack Integration") {
                    TextField("Slack Webhook URL", text: $integrations.slackWebhookURL)
                        .textFieldStyle(.roundedBorder)
                }
                GroupBox("Discord Integration") {
                    TextField("Discord Webhook URL", text: $integrations.discordWebhookURL)
                        .textFieldStyle(.roundedBorder)
                }
                GroupBox("Email Integration") {
                    Picker("Default Email App", selection: $integrations.defaultEmailApp) {
                        ForEach(IntegrationManager.EmailApp.allCases, id: \.self) { app in
                            Text(app.rawValue).tag(app)
                        }
                    }
                }
                GroupBox("Notes Integration") {
                    Picker("Default Notes App", selection: $integrations.defaultNotesApp) {
                        ForEach(IntegrationManager.NotesApp.allCases, id: \.self) { app in
                            Text(app.rawValue).tag(app)
                        }
                    }
                }
            }
            .padding()
        }
    }
}
