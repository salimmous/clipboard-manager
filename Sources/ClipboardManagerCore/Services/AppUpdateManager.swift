import Foundation
import AppKit
import UserNotifications

public final class AppUpdateManager: ObservableObject {
    public static let shared = AppUpdateManager()

    @Published public var isUpdateAvailable = false
    @Published public var latestVersion = ""
    @Published public var downloadURL = ""
    @Published public var isChecking = false
    @Published public var lastCheckedDate: Date?
    @Published public var statusMessage = ""

    private var updateTimer: Timer?
    private var updateCheckURL: String {
        "https://api.github.com/repos/\(AppInfo.repoOwnerAndName)/releases/latest"
    }

    private init() {}

    public func startPeriodicCheck() {
        stopPeriodicCheck()
        let hours = max(AppSettings.shared.checkUpdateInterval, 1.0)
        let interval = TimeInterval(hours * 3600)
        updateTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.checkForUpdates()
        }
        checkForUpdates()
    }

    public func stopPeriodicCheck() {
        updateTimer?.invalidate()
        updateTimer = nil
    }

    public func checkForUpdates(manual: Bool = false) {
        guard !isChecking else { return }

        isChecking = true
        statusMessage = "Checking for updates..."

        guard let url = URL(string: updateCheckURL) else {
            isChecking = false
            statusMessage = "Invalid update URL"
            return
        }

        var request = URLRequest(url: url)
        request.setValue("ClipboardManager/\(AppInfo.version)", forHTTPHeaderField: "User-Agent")

        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isChecking = false
                self.lastCheckedDate = Date()

                if let error {
                    self.statusMessage = manual ? "Check failed: \(error.localizedDescription)" : ""
                    return
                }

                guard let data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let tagName = json["tag_name"] as? String,
                      let assets = json["assets"] as? [[String: Any]],
                      let dmgAsset = assets.first(where: { ($0["name"] as? String)?.hasSuffix(".dmg") == true }) ?? assets.first,
                      let downloadURL = dmgAsset["browser_download_url"] as? String else {
                    self.statusMessage = manual ? "Could not parse release info" : ""
                    return
                }

                self.latestVersion = tagName
                self.downloadURL = downloadURL

                if Self.isNewerVersion(tagName, than: AppInfo.version) {
                    self.isUpdateAvailable = true
                    self.statusMessage = "Version \(tagName) available"
                    self.showUpdateNotification()
                } else {
                    self.isUpdateAvailable = false
                    self.statusMessage = "Up to date (v\(AppInfo.version))"
                }
            }
        }.resume()
    }

    public static func isNewerVersion(_ version: String, than currentVersion: String) -> Bool {
        let cleanLatest = version.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "v", with: "", options: [.anchored, .caseInsensitive])
            .split(separator: "-").first.map(String.init) ?? version
        let cleanCurrent = currentVersion.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "v", with: "", options: [.anchored, .caseInsensitive])
            .split(separator: "-").first.map(String.init) ?? currentVersion

        let current = cleanCurrent.split(separator: ".").compactMap { Int($0) }
        let latest = cleanLatest.split(separator: ".").compactMap { Int($0) }
        guard !latest.isEmpty else { return false }

        for i in 0..<max(current.count, latest.count) {
            let currentPart = i < current.count ? current[i] : 0
            let latestPart = i < latest.count ? latest[i] : 0

            if latestPart > currentPart { return true }
            if latestPart < currentPart { return false }
        }
        return false
    }

    private func showUpdateNotification() {
        let content = UNMutableNotificationContent()
        content.title = "New Update Available"
        content.body = "Version \(latestVersion) is ready to install."
        content.sound = .default
        content.categoryIdentifier = "UPDATE_CATEGORY"

        let request = UNNotificationRequest(identifier: "UpdateAvailable", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    public func downloadAndInstallUpdate() {
        guard let url = URL(string: downloadURL), url.scheme == "https" else { return }

        let startContent = UNMutableNotificationContent()
        startContent.title = "Downloading Update"
        startContent.body = "Version \(latestVersion) is being downloaded..."
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: "UpdateDownloading", content: startContent, trigger: nil)
        )

        let task = URLSession.shared.downloadTask(with: url) { [weak self] localURL, _, error in
            if let error {
                DispatchQueue.main.async {
                    self?.showDownloadError(error)
                }
                return
            }

            // CRITICAL: URLSession removes `localURL` immediately after this closure returns.
            // Move it synchronously to a persistent temporary path before switching to main queue.
            guard let localURL else { return }
            let stagedURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("ClipboardManager-Update-\(UUID().uuidString).dmg")

            do {
                try FileManager.default.moveItem(at: localURL, to: stagedURL)
            } catch {
                DispatchQueue.main.async {
                    self?.showDownloadError(error)
                }
                return
            }

            DispatchQueue.main.async {
                UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ["UpdateDownloading"])

                let completeContent = UNMutableNotificationContent()
                completeContent.title = "Download Complete"
                completeContent.body = "Ready to install version \(self?.latestVersion ?? "")"
                UNUserNotificationCenter.current().add(
                    UNNotificationRequest(identifier: "UpdateDownloaded", content: completeContent, trigger: nil)
                )

                self?.installUpdate(from: stagedURL)
            }
        }
        task.resume()
    }

    private func showDownloadError(_ error: Error) {
        let content = UNMutableNotificationContent()
        content.title = "Update Failed"
        content.body = "Failed to download update: \(error.localizedDescription)"
        content.sound = .default
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: "UpdateError", content: content, trigger: nil)
        )
    }

    private func installUpdate(from url: URL) {
        if AppSettings.shared.autoInstallUpdates {
            autoInstallAndRestart(from: url)
        } else {
            let alert = NSAlert()
            alert.messageText = "Install Update \(latestVersion)"
            alert.informativeText = "How would you like to install the update?"
            alert.addButton(withTitle: "Auto Install & Restart")
            alert.addButton(withTitle: "Save to Downloads")
            alert.addButton(withTitle: "Cancel")

            switch alert.runModal() {
            case .alertFirstButtonReturn:
                autoInstallAndRestart(from: url)
            case .alertSecondButtonReturn:
                downloadToDownloads(from: url)
            default:
                try? FileManager.default.removeItem(at: url)
            }
        }
    }

    private func autoInstallAndRestart(from dmgURL: URL) {
        let targetAppURL = URL(fileURLWithPath: "/Applications/ClipboardManager.app")
        let scriptURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("clipboardmanager_install_\(UUID().uuidString).sh")

        // Paths are passed as positional parameters ($1, $2, $3) rather than interpolated into shell code.
        let script = """
        #!/bin/bash
        set -euo pipefail
        DMG_PATH="$1"
        TARGET_APP="$2"
        EXPECTED_BUNDLE_ID="$3"
        SCRIPT_PATH="$0"

        cleanup() {
            if [ -n "${MOUNT_POINT:-}" ] && [ -d "$MOUNT_POINT" ]; then
                hdiutil detach "$MOUNT_POINT" -quiet || hdiutil detach "$MOUNT_POINT" -force -quiet || true
            fi
            rm -f "$DMG_PATH" "$SCRIPT_PATH"
        }
        trap cleanup EXIT

        sleep 1.5
        MOUNT_POINT=$(hdiutil attach "$DMG_PATH" -nobrowse -readonly | awk -F'\\t' '/\\/Volumes\\// {print $NF; exit}')
        if [ -z "$MOUNT_POINT" ] || [ ! -d "$MOUNT_POINT" ]; then
            exit 1
        fi

        APP_SRC="$MOUNT_POINT/ClipboardManager.app"
        if [ ! -d "$APP_SRC" ]; then
            exit 1
        fi

        FOUND_ID=$(plutil -extract CFBundleIdentifier raw "$APP_SRC/Contents/Info.plist" 2>/dev/null || true)
        if [ "$FOUND_ID" != "$EXPECTED_BUNDLE_ID" ]; then
            exit 1
        fi

        BACKUP_APP="${TARGET_APP}.backup"
        rm -rf "$BACKUP_APP"
        if [ -d "$TARGET_APP" ]; then
            mv "$TARGET_APP" "$BACKUP_APP"
        fi

        if cp -R "$APP_SRC" "$TARGET_APP"; then
            rm -rf "$BACKUP_APP"
            open "$TARGET_APP"
        else
            if [ -d "$BACKUP_APP" ]; then
                mv "$BACKUP_APP" "$TARGET_APP"
            fi
            exit 1
        fi
        """

        do {
            try script.write(to: scriptURL, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: scriptURL.path)

            let confirmAlert = NSAlert()
            confirmAlert.messageText = "Ready to Install \(latestVersion)"
            confirmAlert.informativeText = "ClipboardManager will close, replace /Applications/ClipboardManager.app, and relaunch automatically."
            confirmAlert.addButton(withTitle: "Install Now")
            confirmAlert.addButton(withTitle: "Cancel")

            if confirmAlert.runModal() == .alertFirstButtonReturn {
                let task = Process()
                task.executableURL = URL(fileURLWithPath: "/bin/bash")
                task.arguments = [scriptURL.path, dmgURL.path, targetAppURL.path, AppInfo.bundleIdentifier]
                try task.run()

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    NSApplication.shared.terminate(nil)
                }
            } else {
                try? FileManager.default.removeItem(at: scriptURL)
                try? FileManager.default.removeItem(at: dmgURL)
            }
        } catch {
            print("Error creating installation script: \(error)")
            try? FileManager.default.removeItem(at: scriptURL)
            downloadToDownloads(from: dmgURL)
        }
    }

    private func downloadToDownloads(from url: URL) {
        guard let downloadsPath = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first else {
            return
        }
        let safeVersion = latestVersion.replacingOccurrences(of: "/", with: "_")
        let destinationURL = downloadsPath.appendingPathComponent("ClipboardManager-\(safeVersion)-Installer.dmg")

        do {
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            try FileManager.default.moveItem(at: url, to: destinationURL)

            NSWorkspace.shared.selectFile(destinationURL.path, inFileViewerRootedAtPath: downloadsPath.path)

            let alert = NSAlert()
            alert.messageText = "Update Saved"
            alert.informativeText = "Saved to Downloads as \(destinationURL.lastPathComponent)."
            alert.addButton(withTitle: "OK")
            alert.runModal()
        } catch {
            print("Error saving update: \(error)")
        }
    }
}
