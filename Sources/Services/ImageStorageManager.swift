import Foundation

class ImageStorageManager {
    static let shared = ImageStorageManager()
    private let fileManager = FileManager.default
    
    private var imagesDirectory: URL? {
        guard let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return nil }
        let directory = appSupport.appendingPathComponent("ClipboardManager/Images")
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
    
    func saveImage(_ data: Data) -> String? {
        guard let directory = imagesDirectory else { return nil }
        let fileName = UUID().uuidString + ".tiff"
        let fileURL = directory.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
            return fileName
        } catch {
            print("Error saving image: \(error)")
            return nil
        }
    }
    
    func loadImage(fileName: String) -> Data? {
        guard let directory = imagesDirectory else { return nil }
        let fileURL = directory.appendingPathComponent(fileName)
        return try? Data(contentsOf: fileURL)
    }
    
    func deleteImage(fileName: String) {
        guard let directory = imagesDirectory else { return }
        let fileURL = directory.appendingPathComponent(fileName)
        try? fileManager.removeItem(at: fileURL)
    }
}
