import Foundation
import SwiftUI
import AppKit

// MARK: - Clipboard Item Types
enum ClipboardItemType: String, Codable {
    case text = "text"
    case image = "image"
    case url = "url"
}

enum DetectedEntityType: String, Codable {
    case email = "email"
    case phone = "phone"
    case address = "address"
    case none = "none"
}

struct DetectedEntity: Codable, Hashable {
    let type: DetectedEntityType
    let value: String
    let range: String // Store as string since NSRange isn't Codable
}

enum AppearanceMode: String, CaseIterable, Codable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    case blue = "blue"
    case purple = "purple"
    case green = "green"
    case orange = "orange"
    
    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        case .blue: return "Ocean Blue"
        case .purple: return "Purple Haze"
        case .green: return "Forest Green"
        case .orange: return "Sunset Orange"
        }
    }
    
    var accentColor: Color {
        switch self {
        case .system, .light, .dark:
            return .accentColor
        case .blue:
            return .blue
        case .purple:
            return .purple
        case .green:
            return .green
        case .orange:
            return .orange
        }
    }
    
    var backgroundGradient: LinearGradient {
        switch self {
        case .system, .light, .dark:
            return LinearGradient(colors: [Color(NSColor.controlBackgroundColor)], startPoint: .top, endPoint: .bottom)
        case .blue:
            return LinearGradient(colors: [Color.blue.opacity(0.1), Color.cyan.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .purple:
            return LinearGradient(colors: [Color.purple.opacity(0.1), Color.pink.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .green:
            return LinearGradient(colors: [Color.green.opacity(0.1), Color.mint.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .orange:
            return LinearGradient(colors: [Color.orange.opacity(0.1), Color.yellow.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

// MARK: - Clipboard Item Model
struct ClipboardItem: Identifiable, Codable, Hashable {
    let id: UUID
    let content: String
    let type: ClipboardItemType
    var isPinned: Bool
    let timestamp: Date
    var imageFileName: String?
    var detectedEntities: [DetectedEntity] = []
    var ocrText: String? // Vision OCR recognized text from images
    
    var imageData: Data? {
        if let fileName = imageFileName {
            return ImageStorageManager.shared.loadImage(fileName: fileName)
        }
        return nil
    }
    
    enum CodingKeys: String, CodingKey {
        case id, content, type, isPinned, timestamp, imageFileName, imageData, detectedEntities, ocrText
    }
    
    init(content: String, isPinned: Bool = false) {
        self.id = UUID()
        self.content = content
        self.type = .text
        self.isPinned = isPinned
        self.timestamp = Date()
        self.imageFileName = nil
        self.ocrText = nil
        self.detectedEntities = SmartDetector.detectEntities(in: content)
    }
    
    init(imageFileName: String, isPinned: Bool = false, ocrText: String? = nil) {
        self.id = UUID()
        self.content = "Image"
        self.type = .image
        self.isPinned = isPinned
        self.timestamp = Date()
        self.imageFileName = imageFileName
        self.ocrText = ocrText
    }
    
    init(url: String, isPinned: Bool = false) {
        self.id = UUID()
        self.content = url
        self.type = .url
        self.isPinned = isPinned
        self.timestamp = Date()
        self.imageFileName = nil
        self.ocrText = nil
        self.detectedEntities = []
    }
    
    init(id: UUID, content: String, type: ClipboardItemType, isPinned: Bool, timestamp: Date, imageFileName: String?, detectedEntities: [DetectedEntity], ocrText: String? = nil) {
        self.id = id
        self.content = content
        self.type = type
        self.isPinned = isPinned
        self.timestamp = timestamp
        self.imageFileName = imageFileName
        self.detectedEntities = detectedEntities
        self.ocrText = ocrText
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        content = try container.decode(String.self, forKey: .content)
        type = try container.decode(ClipboardItemType.self, forKey: .type)
        isPinned = try container.decode(Bool.self, forKey: .isPinned)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        
        let decodedFileName = try container.decodeIfPresent(String.self, forKey: .imageFileName)
        let decodedImageData = try container.decodeIfPresent(Data.self, forKey: .imageData)
        
        if let fileName = decodedFileName {
            self.imageFileName = fileName
        } else if let data = decodedImageData {
            self.imageFileName = ImageStorageManager.shared.saveImage(data)
        } else {
            self.imageFileName = nil
        }
        
        if let entities = try container.decodeIfPresent([DetectedEntity].self, forKey: .detectedEntities) {
            self.detectedEntities = entities
        } else if type == .text {
            self.detectedEntities = SmartDetector.detectEntities(in: content)
        } else {
            self.detectedEntities = []
        }
        
        self.ocrText = try container.decodeIfPresent(String.self, forKey: .ocrText)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(content, forKey: .content)
        try container.encode(type, forKey: .type)
        try container.encode(isPinned, forKey: .isPinned)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(imageFileName, forKey: .imageFileName)
        try container.encode(detectedEntities, forKey: .detectedEntities)
        try container.encodeIfPresent(ocrText, forKey: .ocrText)
    }
    
    var displayContent: String {
        switch type {
        case .text, .url:
            return content
        case .image:
            if let text = ocrText, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let firstLine = text.components(separatedBy: .newlines).first ?? text
                return "Image: \(firstLine)"
            }
            if let data = imageData {
                return "Image (\(ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file)))"
            }
            return "Image"
        }
    }
    
    var typeIcon: String {
        switch type {
        case .text:
            return "doc.text"
        case .image:
            return "photo"
        case .url:
            return "link"
        }
    }
}
