import Foundation
import AppKit
import UserNotifications

class AppUpdateManager: ObservableObject {
    static let shared = AppUpdateManager()
    
    @Published var isUpdateAvailable = false
    @Published var latestVersion = ""
    @Published var downloadURL = ""
    @Published var isChecking = false
    
    private var updateTimer: Timer?
    private let currentVersion = "1.3.1"
    private let updateCheckURL = "https://api.github.com/repos/salimmous/clipboard-manager/releases/latest"
    
    private init() {}
    
    func startPeriodicCheck() {
        stopPeriodicCheck()
        let interval = TimeInterval(AppSettings().checkUpdateInterval * 3600)
        updateTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            self.checkForUpdates()
        }
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
                      let dmgAsset = assets.first(where: { ($0["name"] as? String)?.hasSuffix(".dmg") == true }) ?? assets.first,
                      let downloadURL = dmgAsset["browser_download_url"] as? String else {
                    return
                }
                
                self?.latestVersion = tagName
                self?.downloadURL = downloadURL
                
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
        let content = UNMutableNotificationContent()
        content.title = "🎉 New Update Available!"
        content.body = "Version \(latestVersion) is ready to install. Tap to update now."
        content.sound = .default
        content.categoryIdentifier = "UPDATE_CATEGORY"
        
        let request = UNNotificationRequest(identifier: "UpdateAvailable", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error showing update notification: \(error)")
            }
        }
    }
    
    func downloadAndInstallUpdate() {
        guard let url = URL(string: downloadURL) else { return }
        
        let startContent = UNMutableNotificationContent()
        startContent.title = "⬇️ Downloading Update"
        startContent.body = "Version \(latestVersion) is being downloaded..."
        let startRequest = UNNotificationRequest(identifier: "UpdateDownloading", content: startContent, trigger: nil)
        UNUserNotificationCenter.current().add(startRequest)
        
        let task = URLSession.shared.downloadTask(with: url) { [weak self] localURL, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.showDownloadError(error)
                }
                return
            }
            
            guard let localURL = localURL else { return }
            
            DispatchQueue.main.async {
                UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ["UpdateDownloading"])
                
                let completeContent = UNMutableNotificationContent()
                completeContent.title = "✅ Download Complete"
                completeContent.body = "Ready to install version \(self?.latestVersion ?? "")"
                let completeRequest = UNNotificationRequest(identifier: "UpdateDownloaded", content: completeContent, trigger: nil)
                UNUserNotificationCenter.current().add(completeRequest)
                
                self?.installUpdate(from: localURL)
            }
        }
        task.resume()
    }
    
    private func showDownloadError(_ error: Error) {
        let content = UNMutableNotificationContent()
        content.title = "❌ Update Failed"
        content.body = "Failed to download update: \(error.localizedDescription)"
        content.sound = .default
        let request = UNNotificationRequest(identifier: "UpdateError", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
    
    private func installUpdate(from url: URL) {
        let settings = AppSettings()
        
        if settings.autoInstallUpdates {
            autoInstallAndRestart(from: url)
        } else {
            let alert = NSAlert()
            alert.messageText = "Install Update"
            alert.informativeText = "How would you like to install the update?"
            alert.addButton(withTitle: "Auto Install & Restart")
            alert.addButton(withTitle: "Download to Downloads")
            alert.addButton(withTitle: "Cancel")
            
            let response = alert.runModal()
            
            switch response {
            case .alertFirstButtonReturn:
                autoInstallAndRestart(from: url)
            case .alertSecondButtonReturn:
                downloadToDownloads(from: url)
            default:
                try? FileManager.default.removeItem(at: url)
            }
        }
    }
    
    private func autoInstallAndRestart(from url: URL) {
        _ = Bundle.main.bundlePath
        let applicationsURL = URL(fileURLWithPath: "/Applications")
        let targetAppURL = applicationsURL.appendingPathComponent("ClipboardManager.app")
        
        let tempDir = FileManager.default.temporaryDirectory
        let scriptURL = tempDir.appendingPathComponent("install_update.sh")
        
        let script = """
        #!/bin/bash
        sleep 2
        hdiutil attach "\(url.path)" -quiet
        VOLUME_PATH="/Volumes/Install ClipboardManager"
        
        if [ -d "$VOLUME_PATH" ]; then
            if [ -d "\(targetAppURL.path)" ]; then
                rm -rf "\(targetAppURL.path)"
            fi
            cp -R "$VOLUME_PATH/ClipboardManager.app" "\(applicationsURL.path)/"
            hdiutil detach "$VOLUME_PATH" -quiet
            rm -f "\(url.path)"
            open "\(targetAppURL.path)"
        fi
        rm -f "\(scriptURL.path)"
        """
        
        do {
            try script.write(to: scriptURL, atomically: true, encoding: .utf8)
            let attributes = [FileAttributeKey.posixPermissions: 0o755]
            try FileManager.default.setAttributes(attributes, ofItemAtPath: scriptURL.path)
            
            let confirmAlert = NSAlert()
            confirmAlert.messageText = "Ready to Install"
            confirmAlert.informativeText = "The app will now close and automatically install the update. The new version will launch automatically."
            confirmAlert.addButton(withTitle: "Install Now")
            confirmAlert.addButton(withTitle: "Cancel")
            
            if confirmAlert.runModal() == .alertFirstButtonReturn {
                let task = Process()
                task.launchPath = "/bin/bash"
                task.arguments = [scriptURL.path]
                task.launch()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    NSApplication.shared.terminate(nil)
                }
            } else {
                try? FileManager.default.removeItem(at: scriptURL)
                try? FileManager.default.removeItem(at: url)
            }
            
        } catch {
            print("Error creating installation script: \(error)")
            downloadToDownloads(from: url)
        }
    }
    
    private func downloadToDownloads(from url: URL) {
        let downloadsPath = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
        let destinationURL = downloadsPath.appendingPathComponent("ClipboardManager-\(latestVersion)-Installer.dmg")
        
        do {
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            try FileManager.default.moveItem(at: url, to: destinationURL)
            
            NSWorkspace.shared.selectFile(destinationURL.path, inFileViewerRootedAtPath: downloadsPath.path)
            
            let alert = NSAlert()
            alert.messageText = "Update Downloaded Successfully"
            alert.informativeText = "The new version has been saved to the Downloads folder. Please install it manually when ready."
            alert.addButton(withTitle: "OK")
            alert.runModal()
            
        } catch {
            print("Error downloading update: \(error)")
        }
    }
}
