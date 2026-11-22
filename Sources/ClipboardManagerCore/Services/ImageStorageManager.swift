import Foundation
import AppKit

public struct SavedImageMetadata {
    public let fileName: String
    public let width: Int?
    public let height: Int?
    public let byteCount: Int
}

public final class ImageStorageManager {
    public static let shared = ImageStorageManager()

    private let fileManager = FileManager.default
    private let customDirectory: URL?
    private let ioQueue = DispatchQueue(label: "com.clipboardmanager.imagestorage", qos: .userInitiated)
    private let thumbnailCache = NSCache<NSString, NSImage>()
    private let fullImageCache = NSCache<NSString, NSImage>()

    public init(directory: URL? = nil) {
        self.customDirectory = directory
        thumbnailCache.countLimit = 150
        thumbnailCache.totalCostLimit = 25 * 1024 * 1024
        fullImageCache.countLimit = 20
        fullImageCache.totalCostLimit = 60 * 1024 * 1024
    }

    public var imagesDirectory: URL? {
        if let customDirectory {
            try? fileManager.createDirectory(at: customDirectory, withIntermediateDirectories: true)
            return customDirectory
        }
        let directory = AppInfo.appSupportDirectory.appendingPathComponent("Images", isDirectory: true)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    public func saveImage(_ data: Data) -> String? {
        saveImageWithMetadata(data)?.fileName
    }

    /// Compresses raw image data (e.g. bulky TIFF) to PNG when possible and returns dimensions + size.
    public func saveImageWithMetadata(_ data: Data) -> SavedImageMetadata? {
        guard let directory = imagesDirectory else { return nil }

        let (outputData, ext, width, height) = normalizeImageData(data)
        let fileName = UUID().uuidString + "." + ext
        let fileURL = directory.appendingPathComponent(fileName)

        do {
            try outputData.write(to: fileURL, options: .atomic)
            return SavedImageMetadata(
                fileName: fileName,
                width: width,
                height: height,
                byteCount: outputData.count
            )
        } catch {
            print("Error saving image: \(error)")
            return nil
        }
    }

    public func loadImageData(fileName: String) -> Data? {
        guard let directory = imagesDirectory else { return nil }
        let fileURL = directory.appendingPathComponent(fileName)
        return try? Data(contentsOf: fileURL)
    }

    /// Backwards-compatible alias.
    public func loadImage(fileName: String) -> Data? {
        loadImageData(fileName: fileName)
    }

    public func cachedThumbnail(fileName: String) -> NSImage? {
        thumbnailCache.object(forKey: fileName as NSString)
    }

    public func loadThumbnail(fileName: String, maxPixelSize: CGFloat = 80, completion: @escaping (NSImage?) -> Void) {
        let key = fileName as NSString
        if let cached = thumbnailCache.object(forKey: key) {
            completion(cached)
            return
        }

        ioQueue.async { [weak self] in
            guard let self, let data = self.loadImageData(fileName: fileName),
                  let image = NSImage(data: data) else {
                DispatchQueue.main.async { completion(nil) }
                return
            }

            let thumb = self.downsample(image: image, maxDimension: maxPixelSize)
            let cost = Int(thumb.size.width * thumb.size.height * 4)
            self.thumbnailCache.setObject(thumb, forKey: key, cost: max(cost, 1))

            DispatchQueue.main.async {
                completion(thumb)
            }
        }
    }

    public func loadFullImage(fileName: String, completion: @escaping (NSImage?) -> Void) {
        let key = fileName as NSString
        if let cached = fullImageCache.object(forKey: key) {
            completion(cached)
            return
        }

        ioQueue.async { [weak self] in
            guard let self, let data = self.loadImageData(fileName: fileName),
                  let image = NSImage(data: data) else {
                DispatchQueue.main.async { completion(nil) }
                return
            }

            self.fullImageCache.setObject(image, forKey: key, cost: max(data.count, 1))
            DispatchQueue.main.async {
                completion(image)
            }
        }
    }

    public func deleteImage(fileName: String) {
        let key = fileName as NSString
        thumbnailCache.removeObject(forKey: key)
        fullImageCache.removeObject(forKey: key)

        guard let directory = imagesDirectory else { return }
        let fileURL = directory.appendingPathComponent(fileName)
        try? fileManager.removeItem(at: fileURL)
    }

    /// Deletes any files in the Images directory not referenced by active clipboard items.
    public func cleanupOrphanedImages(keeping validFileNames: Set<String>) {
        guard let directory = imagesDirectory,
              let files = try? fileManager.contentsOfDirectory(atPath: directory.path) else { return }

        for file in files where !validFileNames.contains(file) {
            let fileURL = directory.appendingPathComponent(file)
            try? fileManager.removeItem(at: fileURL)
            thumbnailCache.removeObject(forKey: file as NSString)
            fullImageCache.removeObject(forKey: file as NSString)
        }
    }

    private func normalizeImageData(_ data: Data) -> (data: Data, ext: String, width: Int?, height: Int?) {
        // Check if already PNG magic bytes (89 50 4E 47)
        let isPNG = data.count >= 4 && data[0] == 0x89 && data[1] == 0x50 && data[2] == 0x4E && data[3] == 0x47
        // Check if already JPEG magic bytes (FF D8 FF)
        let isJPEG = data.count >= 3 && data[0] == 0xFF && data[1] == 0xD8 && data[2] == 0xFF

        if let rep = NSBitmapImageRep(data: data) {
            let w = rep.pixelsWide > 0 ? rep.pixelsWide : Int(rep.size.width)
            let h = rep.pixelsHigh > 0 ? rep.pixelsHigh : Int(rep.size.height)

            if isPNG {
                return (data, "png", w, h)
            }
            if isJPEG {
                return (data, "jpg", w, h)
            }
            if let pngData = rep.representation(using: .png, properties: [:]) {
                return (pngData, "png", w, h)
            }
            return (data, "tiff", w, h)
        }

        if let image = NSImage(data: data) {
            let w = Int(image.size.width)
            let h = Int(image.size.height)
            if let tiff = image.tiffRepresentation,
               let rep = NSBitmapImageRep(data: tiff),
               let pngData = rep.representation(using: .png, properties: [:]) {
                return (pngData, "png", rep.pixelsWide, rep.pixelsHigh)
            }
            return (data, isPNG ? "png" : (isJPEG ? "jpg" : "tiff"), w > 0 ? w : nil, h > 0 ? h : nil)
        }

        return (data, "bin", nil, nil)
    }

    private func downsample(image: NSImage, maxDimension: CGFloat) -> NSImage {
        let size = image.size
        guard size.width > 0, size.height > 0 else { return image }

        let scale = min(maxDimension / size.width, maxDimension / size.height, 1.0)
        let targetSize = NSSize(width: max(1, floor(size.width * scale)), height: max(1, floor(size.height * scale)))

        let resized = NSImage(size: targetSize)
        resized.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        image.draw(in: NSRect(origin: .zero, size: targetSize), from: NSRect(origin: .zero, size: size), operation: .copy, fraction: 1.0)
        resized.unlockFocus()
        return resized
    }
}
