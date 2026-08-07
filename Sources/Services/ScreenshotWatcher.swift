import Foundation
import AppKit

class ScreenshotWatcher: ObservableObject {
    private var sources: [DispatchSourceFileSystemObject] = []
    private let fileManager = FileManager.default
    private var lastKnownFiles: [URL: Set<String>] = [:]
    
    private var screenshotDirectories: [URL] {
        var dirs: [URL] = []
        
        // 1. Check user-configured com.apple.screencapture location
        if let location = UserDefaults(suiteName: "com.apple.screencapture")?.string(forKey: "location") {
            let expanded = (location as NSString).expandingTildeInPath
            var isDir: ObjCBool = false
            if fileManager.fileExists(atPath: expanded, isDirectory: &isDir), isDir.boolValue {
                dirs.append(URL(fileURLWithPath: expanded))
            }
        }
        
        // 2. Add ~/Desktop
        if let desktop = fileManager.urls(for: .desktopDirectory, in: .userDomainMask).first {
            if !dirs.contains(desktop) {
                dirs.append(desktop)
            }
        }
        
        // 3. Add ~/Downloads (common screenshot location)
        if let downloads = fileManager.urls(for: .downloadsDirectory, in: .userDomainMask).first {
            if !dirs.contains(downloads) {
                dirs.append(downloads)
            }
        }
        
        return dirs
    }
    
    func startWatching() {
        stopWatching()
        
        for directory in screenshotDirectories {
            var isDir: ObjCBool = false
            guard fileManager.fileExists(atPath: directory.path, isDirectory: &isDir), isDir.boolValue else { continue }
            
            updateLastKnownFiles(in: directory)
            
            let descriptor = open(directory.path, O_EVTONLY)
            guard descriptor > 0 else { continue }
            
            let source = DispatchSource.makeFileSystemObjectSource(fileDescriptor: descriptor, eventMask: .write, queue: DispatchQueue.global())
            
            source.setEventHandler { [weak self] in
                self?.checkForNewScreenshots(in: directory)
            }
            
            source.setCancelHandler {
                close(descriptor)
            }
            
            source.resume()
            sources.append(source)
        }
    }
    
    func stopWatching() {
        for source in sources {
            source.cancel()
        }
        sources.removeAll()
    }
    
    private func updateLastKnownFiles(in directory: URL) {
        guard let files = try? fileManager.contentsOfDirectory(atPath: directory.path) else { return }
        lastKnownFiles[directory] = Set(files)
    }
    
    private func checkForNewScreenshots(in directory: URL) {
        guard let currentFiles = try? fileManager.contentsOfDirectory(atPath: directory.path) else { return }
        
        let previousFiles = lastKnownFiles[directory] ?? []
        let currentFileSet = Set(currentFiles)
        let newFiles = currentFileSet.subtracting(previousFiles)
        lastKnownFiles[directory] = currentFileSet
        
        for file in newFiles {
            let lower = file.lowercased()
            let isImage = lower.hasSuffix(".png") || lower.hasSuffix(".jpg") || lower.hasSuffix(".jpeg") || lower.hasSuffix(".heic") || lower.hasSuffix(".webp")
            let isScreenshot = lower.contains("screenshot") || 
                               lower.contains("capture") || 
                               lower.contains("لقطة") || 
                               lower.contains("écran") || 
                               lower.contains("ecran") || 
                               lower.contains("pantalla") || 
                               lower.contains("bildschirm") || 
                               lower.contains("shot") || 
                               file.hasPrefix("CleanShot") ||
                               file.hasPrefix("Shottr")
            
            if isImage && isScreenshot {
                let fileURL = directory.appendingPathComponent(file)
                
                DispatchQueue.global().asyncAfter(deadline: .now() + 0.3) {
                    if let data = try? Data(contentsOf: fileURL) {
                        DispatchQueue.main.async {
                            ClipboardManager.shared.addScreenshotItem(data)
                        }
                    }
                }
            }
        }
    }
}
