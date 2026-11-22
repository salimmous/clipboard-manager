import Foundation
import SwiftUI
import AppKit

// MARK: - Clipboard Item Types
public enum ClipboardItemType: String, Codable, CaseIterable {
    case text = "text"
    case image = "image"
    case url = "url"
}

public enum DetectedEntityType: String, Codable {
    case email = "email"
    case phone = "phone"
    case address = "address"
    case color = "color"
    case none = "none"
}

public struct DetectedEntity: Codable, Hashable {
    public let type: DetectedEntityType
    public let value: String
    public let range: String

    public init(type: DetectedEntityType, value: String, range: String) {
        self.type = type
        self.value = value
        self.range = range
    }

    public var actionTitle: String {
        switch type {
        case .email: return "Compose"
        case .phone: return "Call"
        case .address: return "Maps"
        case .color: return "Copy Hex"
        case .none: return "Open"
        }
    }

    public var iconName: String {
        switch type {
        case .email: return "envelope"
        case .phone: return "phone"
        case .address: return "map"
        case .color: return "paintpalette"
        case .none: return "sparkles"
        }
    }
}

public enum AppearanceMode: String, CaseIterable, Codable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    case blue = "blue"
    case purple = "purple"
    case green = "green"
    case orange = "orange"

    public var displayName: String {
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

    public var accentColor: Color {
        switch self {
        case .system, .light, .dark: return .accentColor
        case .blue: return .blue
        case .purple: return .purple
        case .green: return .green
        case .orange: return .orange
        }
    }

    public var backgroundGradient: LinearGradient {
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
public struct ClipboardItem: Identifiable, Codable, Hashable {
    public let id: UUID
    public let content: String
    public let type: ClipboardItemType
    public var isPinned: Bool
    public let timestamp: Date
    public var imageFileName: String?
    public var detectedEntities: [DetectedEntity] = []
    public var ocrText: String?
    public var sourceAppBundleID: String?
    public var sourceAppName: String?
    public var imageWidth: Int?
    public var imageHeight: Int?
    public var imageByteCount: Int?

    public var imageData: Data? {
        if let fileName = imageFileName {
            return ImageStorageManager.shared.loadImageData(fileName: fileName)
        }
        return nil
    }

    enum CodingKeys: String, CodingKey {
        case id, content, type, isPinned, timestamp, imageFileName, imageData
        case detectedEntities, ocrText, sourceAppBundleID, sourceAppName
        case imageWidth, imageHeight, imageByteCount
    }

    public init(
        content: String,
        isPinned: Bool = false,
        sourceAppBundleID: String? = nil,
        sourceAppName: String? = nil,
        detectEntities: Bool = true
    ) {
        self.id = UUID()
        self.content = content
        self.type = .text
        self.isPinned = isPinned
        self.timestamp = Date()
        self.imageFileName = nil
        self.ocrText = nil
        self.sourceAppBundleID = sourceAppBundleID
        self.sourceAppName = sourceAppName
        self.detectedEntities = detectEntities ? SmartDetector.detectEntities(in: content) : []
    }

    public init(
        imageFileName: String,
        isPinned: Bool = false,
        ocrText: String? = nil,
        sourceAppBundleID: String? = nil,
        sourceAppName: String? = nil,
        imageWidth: Int? = nil,
        imageHeight: Int? = nil,
        imageByteCount: Int? = nil
    ) {
        self.id = UUID()
        self.content = "Image"
        self.type = .image
        self.isPinned = isPinned
        self.timestamp = Date()
        self.imageFileName = imageFileName
        self.ocrText = ocrText
        self.sourceAppBundleID = sourceAppBundleID
        self.sourceAppName = sourceAppName
        self.imageWidth = imageWidth
        self.imageHeight = imageHeight
        self.imageByteCount = imageByteCount
    }

    public init(
        url: String,
        isPinned: Bool = false,
        sourceAppBundleID: String? = nil,
        sourceAppName: String? = nil
    ) {
        self.id = UUID()
        self.content = url
        self.type = .url
        self.isPinned = isPinned
        self.timestamp = Date()
        self.imageFileName = nil
        self.ocrText = nil
        self.sourceAppBundleID = sourceAppBundleID
        self.sourceAppName = sourceAppName
        self.detectedEntities = []
    }

    public init(
        id: UUID,
        content: String,
        type: ClipboardItemType,
        isPinned: Bool,
        timestamp: Date,
        imageFileName: String?,
        detectedEntities: [DetectedEntity],
        ocrText: String? = nil,
        sourceAppBundleID: String? = nil,
        sourceAppName: String? = nil,
        imageWidth: Int? = nil,
        imageHeight: Int? = nil,
        imageByteCount: Int? = nil
    ) {
        self.id = id
        self.content = content
        self.type = type
        self.isPinned = isPinned
        self.timestamp = timestamp
        self.imageFileName = imageFileName
        self.detectedEntities = detectedEntities
        self.ocrText = ocrText
        self.sourceAppBundleID = sourceAppBundleID
        self.sourceAppName = sourceAppName
        self.imageWidth = imageWidth
        self.imageHeight = imageHeight
        self.imageByteCount = imageByteCount
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        content = try container.decode(String.self, forKey: .content)
        type = try container.decode(ClipboardItemType.self, forKey: .type)
        isPinned = try container.decode(Bool.self, forKey: .isPinned)
        timestamp = try container.decode(Date.self, forKey: .timestamp)

        let decodedFileName = try container.decodeIfPresent(String.self, forKey: .imageFileName)
        let decodedImageData = try container.decodeIfPresent(Data.self, forKey: .imageData)

        var migratedWidth: Int?
        var migratedHeight: Int?
        var migratedByteCount: Int?

        if let fileName = decodedFileName {
            self.imageFileName = fileName
        } else if let data = decodedImageData, let saved = ImageStorageManager.shared.saveImageWithMetadata(data) {
            self.imageFileName = saved.fileName
            migratedWidth = saved.width
            migratedHeight = saved.height
            migratedByteCount = saved.byteCount
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
        self.sourceAppBundleID = try container.decodeIfPresent(String.self, forKey: .sourceAppBundleID)
        self.sourceAppName = try container.decodeIfPresent(String.self, forKey: .sourceAppName)
        self.imageWidth = try container.decodeIfPresent(Int.self, forKey: .imageWidth) ?? migratedWidth
        self.imageHeight = try container.decodeIfPresent(Int.self, forKey: .imageHeight) ?? migratedHeight
        self.imageByteCount = try container.decodeIfPresent(Int.self, forKey: .imageByteCount) ?? migratedByteCount
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(content, forKey: .content)
        try container.encode(type, forKey: .type)
        try container.encode(isPinned, forKey: .isPinned)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encodeIfPresent(imageFileName, forKey: .imageFileName)
        try container.encode(detectedEntities, forKey: .detectedEntities)
        try container.encodeIfPresent(ocrText, forKey: .ocrText)
        try container.encodeIfPresent(sourceAppBundleID, forKey: .sourceAppBundleID)
        try container.encodeIfPresent(sourceAppName, forKey: .sourceAppName)
        try container.encodeIfPresent(imageWidth, forKey: .imageWidth)
        try container.encodeIfPresent(imageHeight, forKey: .imageHeight)
        try container.encodeIfPresent(imageByteCount, forKey: .imageByteCount)
    }

    /// Zero-disk-I/O display string safe to call inside SwiftUI `body`.
    public var displayContent: String {
        switch type {
        case .text, .url:
            return content
        case .image:
            if let text = ocrText?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty {
                let firstLine = text.components(separatedBy: .newlines).first(where: { !$0.isEmpty }) ?? text
                return "Image: \(firstLine)"
            }
            if let w = imageWidth, let h = imageHeight, w > 0, h > 0 {
                if let bytes = imageByteCount {
                    return "Image (\(w)×\(h), \(ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)))"
                }
                return "Image (\(w)×\(h))"
            }
            if let bytes = imageByteCount {
                return "Image (\(ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)))"
            }
            return "Image"
        }
    }

    public var hexColorSwatch: Color? {
        guard type == .text else { return nil }
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let rgba = SmartDetector.parseHexColor(trimmed) else { return nil }
        return Color(NSColor(red: rgba.r, green: rgba.g, blue: rgba.b, alpha: rgba.a))
    }

    public var metadataSummary: String {
        switch type {
        case .text:
            let chars = content.count
            let lines = content.components(separatedBy: .newlines).count
            return lines > 1 ? "\(chars) chars • \(lines) lines" : "\(chars) chars"
        case .url:
            return URL(string: content)?.host ?? "Link"
        case .image:
            var parts: [String] = []
            if let w = imageWidth, let h = imageHeight, w > 0, h > 0 {
                parts.append("\(w)×\(h)")
            }
            if let bytes = imageByteCount {
                parts.append(ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file))
            }
            return parts.isEmpty ? "Image" : parts.joined(separator: " • ")
        }
    }

    public var typeIcon: String {
        switch type {
        case .text: return "doc.text"
        case .image: return "photo"
        case .url: return "link"
        }
    }
}
