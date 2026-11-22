import Foundation
import AppKit

public final class ScreenshotWatcher: ObservableObject {
    private var sources: [DispatchSourceFileSystemObject] = []
    private let fileManager = FileManager.default
    private let watchQueue = DispatchQueue(label: "com.clipboardmanager.screenshotwatcher", qos: .utility)
    private var lastKnownFiles: [URL: Set<String>] = [:]

    public init() {}

    private var screenshotDirectories: [URL] {
        var dirs: [URL] = []

        if let location = UserDefaults(suiteName: "com.apple.screencapture")?.string(forKey: "location") {
            let expanded = (location as NSString).expandingTildeInPath
            var isDir: ObjCBool = false
            if fileManager.fileExists(atPath: expanded, isDirectory: &isDir), isDir.boolValue {
                dirs.append(URL(fileURLWithPath: expanded).standardizedFileURL)
            }
        }

        if let desktop = fileManager.urls(for: .desktopDirectory, in: .userDomainMask).first?.standardizedFileURL,
           !dirs.contains(desktop) {
            dirs.append(desktop)
        }

        if let downloads = fileManager.urls(for: .downloadsDirectory, in: .userDomainMask).first?.standardizedFileURL,
           !dirs.contains(downloads) {
            dirs.append(downloads)
        }

        return dirs
    }

    public func startWatching() {
        watchQueue.async { [weak self] in
            guard let self else { return }
            self.stopWatchingLocked()

            for directory in self.screenshotDirectories {
                var isDir: ObjCBool = false
                guard self.fileManager.fileExists(atPath: directory.path, isDirectory: &isDir), isDir.boolValue else {
                    continue
                }

                self.updateLastKnownFilesLocked(in: directory)

                let descriptor = open(directory.path, O_EVTONLY)
                guard descriptor >= 0 else { continue }

                let source = DispatchSource.makeFileSystemObjectSource(
                    fileDescriptor: descriptor,
                    eventMask: .write,
                    queue: self.watchQueue
                )

                source.setEventHandler { [weak self] in
                    self?.checkForNewScreenshotsLocked(in: directory)
                }

                source.setCancelHandler {
                    close(descriptor)
                }

                source.resume()
                self.sources.append(source)
            }
        }
    }

    public func stopWatching() {
        watchQueue.async { [weak self] in
            self?.stopWatchingLocked()
        }
    }

    private func stopWatchingLocked() {
        for source in sources {
            source.cancel()
        }
        sources.removeAll()
    }

    private func updateLastKnownFilesLocked(in directory: URL) {
        guard let files = try? fileManager.contentsOfDirectory(atPath: directory.path) else { return }
        lastKnownFiles[directory] = Set(files)
    }

    private func checkForNewScreenshotsLocked(in directory: URL) {
        guard let currentFiles = try? fileManager.contentsOfDirectory(atPath: directory.path) else { return }

        let previousFiles = lastKnownFiles[directory] ?? []
        let currentFileSet = Set(currentFiles)
        let newFiles = currentFileSet.subtracting(previousFiles)
        lastKnownFiles[directory] = currentFileSet

        for file in newFiles {
            guard !file.hasPrefix(".") else { continue }
            let lower = file.lowercased()
            let isImage = lower.hasSuffix(".png") || lower.hasSuffix(".jpg") || lower.hasSuffix(".jpeg")
                || lower.hasSuffix(".heic") || lower.hasSuffix(".webp")
            let isScreenshot = lower.contains("screenshot")
                || lower.contains("capture")
                || lower.contains("لقطة")
                || lower.contains("écran")
                || lower.contains("ecran")
                || lower.contains("pantalla")
                || lower.contains("bildschirm")
                || lower.contains("shot")
                || file.hasPrefix("CleanShot")
                || file.hasPrefix("Shottr")

            guard isImage && isScreenshot else { continue }
            let fileURL = directory.appendingPathComponent(file)

            watchQueue.asyncAfter(deadline: .now() + 0.35) {
                guard let data = try? Data(contentsOf: fileURL), !data.isEmpty else { return }
                DispatchQueue.main.async {
                    guard !ClipboardManager.shared.isPaused else { return }
                    ClipboardManager.shared.addScreenshotItem(data)
                }
            }
        }
    }
}
