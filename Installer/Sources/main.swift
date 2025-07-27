import SwiftUI
import AppKit

// MARK: - Installer Window
struct InstallerView: View {
    @State private var isInstalling = false
    @State private var installationProgress: Double = 0.0
    @State private var installationComplete = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with gradient background
            VStack(spacing: 20) {
                // App Logo and Title
                VStack(spacing: 16) {
                    // App Icon
                    if let logoImage = NSImage(named: "clipboard-logo.png") {
                        Image(nsImage: logoImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 120, height: 120)
                            .shadow(color: .blue.opacity(0.3), radius: 15, x: 0, y: 8)
                    } else {
                        Image(systemName: "doc.on.clipboard.fill")
                            .font(.system(size: 120, weight: .light))
                            .foregroundColor(.blue)
                            .shadow(color: .blue.opacity(0.3), radius: 15, x: 0, y: 8)
                    }
                    
                    // App Name
                    VStack(spacing: 8) {
                        Text("ClipboardManager")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text("Smart Clipboard Management for macOS")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                
                // Installation Status
                if !installationComplete {
                    VStack(spacing: 16) {
                        if !isInstalling {
                            Text("Ready to install ClipboardManager")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.primary)
                        } else {
                            VStack(spacing: 12) {
                                Text("Installing ClipboardManager...")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(.primary)
                                
                                ProgressView(value: installationProgress, total: 1.0)
                                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                                    .frame(width: 300)
                                    .scaleEffect(1.2)
                                
                                Text(String(format: "%.0f%%", installationProgress * 100))
                                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        
                        Text("Installation Complete!")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.green)
                        
                        Text("ClipboardManager has been successfully installed")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.top, 60)
            .padding(.bottom, 40)
            .padding(.horizontal, 40)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: [Color.white, Color.gray.opacity(0.05)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            
            // Action Buttons
            HStack(spacing: 20) {
                if !installationComplete {
                    if !isInstalling {
                        Button(action: {
                            startInstallation()
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "arrow.down.circle.fill")
                                    .font(.system(size: 20))
                                Text("Install ClipboardManager")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [.blue, .blue.opacity(0.8)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .cornerRadius(12)
                            .shadow(color: .blue.opacity(0.4), radius: 10, x: 0, y: 5)
                        }
                        .buttonStyle(.plain)
                        .scaleEffect(1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isInstalling)
                        
                        Button(action: {
                            NSApplication.shared.terminate(nil)
                        }) {
                            Text("Cancel")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                        }
                        .buttonStyle(.plain)
                    }
                } else {
                    Button(action: {
                        launchApplication()
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 20))
                            Text("Launch ClipboardManager")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [.green, .green.opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .cornerRadius(12)
                        .shadow(color: .green.opacity(0.4), radius: 10, x: 0, y: 5)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        NSApplication.shared.terminate(nil)
                    }) {
                        Text("Close")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.bottom, 40)
        }
        .frame(width: 600, height: 500)
        .background(Color.white)
        .alert("Installation Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func startInstallation() {
        isInstalling = true
        installationProgress = 0.0
        
        // Simulate installation process
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            installationProgress += 0.02
            
            if installationProgress >= 1.0 {
                timer.invalidate()
                performActualInstallation()
            }
        }
    }
    
    private func performActualInstallation() {
        // Get the embedded app bundle from Resources
        guard let resourcePath = Bundle.main.resourcePath else {
            showError("Could not find installer resources")
            return
        }
        
        let embeddedAppPath = resourcePath + "/ClipboardManager.app"
        
        if !FileManager.default.fileExists(atPath: embeddedAppPath) {
            showError("Could not find ClipboardManager.app in installer")
            return
        }
        
        // Applications folder path
        let applicationsPath = "/Applications/ClipboardManager.app"
        
        do {
            // Remove existing installation if it exists
            if FileManager.default.fileExists(atPath: applicationsPath) {
                try FileManager.default.removeItem(atPath: applicationsPath)
            }
            
            // Copy the app to Applications folder
            try FileManager.default.copyItem(atPath: embeddedAppPath, toPath: applicationsPath)
            
            // Installation complete
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                installationComplete = true
                isInstalling = false
            }
            
        } catch {
            showError("Installation failed: \(error.localizedDescription)")
        }
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
        isInstalling = false
        installationProgress = 0.0
    }
    
    private func launchApplication() {
        let applicationsPath = "/Applications/ClipboardManager.app"
        NSWorkspace.shared.openApplication(at: URL(fileURLWithPath: applicationsPath), configuration: NSWorkspace.OpenConfiguration()) { _, _ in
            NSApplication.shared.terminate(nil)
        }
    }
}

// MARK: - Installer App
@main
struct InstallerApp: App {
    var body: some Scene {
        WindowGroup {
            InstallerView()
        }
        .windowStyle(.hiddenTitleBar)
    }
}