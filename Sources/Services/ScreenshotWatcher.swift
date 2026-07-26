import Foundation
import AppKit

class ScreenshotWatcher: ObservableObject {
    private var source: DispatchSourceFileSystemObject?
    private let fileManager = FileManager.default
    private var lastKnownFiles: Set<String> = []
    
    private var desktopURL: URL? {
        fileManager.urls(for: .desktopDirectory, in: .userDomainMask).first
    }
    
    func startWatching() {
        stopWatching()
        
        guard let desktopURL = desktopURL else { return }
        
        // Check if Desktop directory exists and is accessible
        var isDir: ObjCBool = false
        guard fileManager.fileExists(atPath: desktopURL.path, isDirectory: &isDir), isDir.boolValue else { return }
        
        updateLastKnownFiles(in: desktopURL)
        
        let descriptor = open(desktopURL.path, O_EVTONLY)
        guard descriptor > 0 else { return }
        
        source = DispatchSource.makeFileSystemObjectSource(fileDescriptor: descriptor, eventMask: .write, queue: DispatchQueue.global())
        
        source?.setEventHandler { [weak self] in
            self?.checkForNewScreenshots()
        }
        
        source?.setCancelHandler {
            close(descriptor)
        }
        
        source?.resume()
    }
    
    func stopWatching() {
        source?.cancel()
        source = nil
    }
    
    private func updateLastKnownFiles(in directory: URL) {
        guard let files = try? fileManager.contentsOfDirectory(atPath: directory.path) else { return }
        lastKnownFiles = Set(files)
    }
    
    private func checkForNewScreenshots() {
        guard let directory = desktopURL,
              let currentFiles = try? fileManager.contentsOfDirectory(atPath: directory.path) else { return }
        
        let currentFileSet = Set(currentFiles)
        let newFiles = currentFileSet.subtracting(lastKnownFiles)
        lastKnownFiles = currentFileSet
        
        for file in newFiles {
            if (file.hasPrefix("Screenshot") || file.hasPrefix("Capture")) && 
               (file.hasSuffix(".png") || file.hasSuffix(".jpg") || file.hasSuffix(".jpeg") || file.hasSuffix(".heic")) {
                
                let fileURL = directory.appendingPathComponent(file)
                
                DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
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
